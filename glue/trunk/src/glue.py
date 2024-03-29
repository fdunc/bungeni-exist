""" 

    REQUIRES : Jython , NOT Python

    Performs XSLT transformations on Bungeni documents and outputs ontological documents;
    synchronizes with eXist-db; translates .po files to .xml catalogues

    transformation process:
        -get parliament's information
        -look for documents with attachments and bind them
        -transform Bungeni documents and add the bu: namespace
        -synchronize with collection in eXist-db to create upload list
        -upload XML documents + attachments to eXist database
    other actions:
        -translate .po files to .xml catalogues
        !+NOTE: Use of polib requires one to install it to Jython as follows:
        /path/to/jython2.5.2/bin/easy_install polib
"""

import os.path, sys, errno, getopt, shutil, codecs
import time

__author__ = "Ashok Hariharan and Anthony Oduor"
__copyright__ = "Copyright 2011, Bungeni"
__license__ = "GNU GPL v3"
__version__ = "1.4.0"
__maintainer__ = "Anthony Oduor"
__created__ = "18th Oct 2011"
__status__ = "Development"

#__parl_info__ = "parliament_info.xml"
#__repo_sync__ = "reposync.xml"

__sax_parser_factory__ = "org.apache.xerces.jaxp.SAXParserFactoryImpl"


from java.io import (
    File,
    OutputStreamWriter,
    BufferedWriter,
    FileOutputStream
    )

from java.lang import StringBuilder

from org.apache.log4j import (
    PropertyConfigurator,
    Logger
    )

from org.apache.http.conn import HttpHostConnectException

### APP Imports ####

from configs import (
    __pipeline_configs_file,
    __type_mappings_file,
    __pipelines_file,
    TransformerConfig,
    WebDavConfig,
    PoTranslationsConfig,
    RabbitMqConfig
    )

from gen_utils import (
    COLOR,
    mkdir_p,
    __setup_tmp_dir__,
    __setup_tmp_dirs__,
    __setup_output_dirs__,
    __setup_cache_dirs__,
    get_module_dir,
    LegislatureCacheInfo,
    ParliamentCacheInfo,
    typename_to_camelcase,
    typename_to_propercase,
    )

from utils import (
    WebDavClient,
    Transformer,
    RepoSyncUploader,
    PostTransform,
    POFilesTranslator,
    )

from parsers import (
    ParseBungeniTypesXML,
    ParsePipelineConfigsXML,
    ParseBungeniXML,
    READ_PARLIAMENT_INFO_PARAMS
    )

from walker import (
    GenericDirWalkerUNZIP
    )

from walker_ext import (
     LegislatureInfo,
     LegislatureInfoProcess,
     ParliamentInfo,
     SeekBindAttachmentsWalker,
     ProcessXmlFilesWalker,
     ProcessedAttsFilesWalker,
     SyncXmlFilesWalker
    )


LOG = Logger.getLogger("glue")


def setup_consumer_directories(config_file):
    cfg = TransformerConfig(config_file)
    __setup_tmp_dir__(cfg)
    __setup_cache_dirs__(cfg)



def __files_by_date(in_folder, file_type_wc):
    import glob
    searchedfile = glob.glob(os.path.join(in_folder, file_type_wc))
    files = sorted(
        searchedfile, 
        key = lambda a_file: os.path.getctime(a_file)
    )
    return files

    
def __most_recent_file(in_folder, file_type_wc):
    files = __files_by_date(in_folder, file_type_wc)
    if len(files) > 0:
        return files[len(files) - 1]
    else:
        return None
    

def get_legislature_info(config_file):
    cfg = TransformerConfig(config_file)
    leg_name = cfg.legislature_type_name()
    print "Legislature type name = ", leg_name
    path_to_legislature_folder = os.path.join(cfg.input_folder(), leg_name)
    print "path to legislature  = ", path_to_legislature_folder
    l_info = LegislatureCacheInfo()
    liw = LegislatureInfoProcess(
        input_params = {"main_config": cfg}
    )
    print "legislature cache file : ", liw.cache_file_exists()
    if liw.cache_file_exists():
        l_info.legislature_info = liw.get_from_cache()
        print "legislature info :", l_info.legislature_info
        return l_info
    else:
        legislature_file = __most_recent_file(path_to_legislature_folder, "*.*")
        print "legislature file = ", legislature_file
        if legislature_file is not None:
            liw = LegislatureInfoProcess(
                   input_params = {"main_config": cfg}
                )
            l_info.legislature_info = liw.process_file(legislature_file)
        else:
            l_info.legislature_info = None
    return l_info
    """
    liw = cfg.
    liw = LegislatureInfoWalker({"main_config": cfg})
    liw.walk(cfg.input_folder)
    return liw.object_info
    """

def get_parl_info(config_file):
    """
    Returns a ParliamentCacheInfo object (see gen_utils)
    This object consists of :
        a list containing 1 or more parliaments
        a variable indicating number of chambers in the legislature
    """
    cfg = TransformerConfig(config_file)
    """
    !+BICAMERAL
    Returns a list containing a map of active parliaments
    This list will have 2 maps in bicameral parliaments
    and 1 map when its unicameral 
    """
    pi = ParliamentInfo(input_params = {"main_config": cfg})
    
    
    #piw = ParliamentInfoWalker({"main_config":cfg})
    #no_of_parliaments_required = 2
    #if piw.bicameral:
    #    no_of_parliaments_required = 3
    # 
    
    pc_info = ParliamentCacheInfo(
        no_of_parls = pi.chambers_required, 
        p_info = []
    )
    #parl_info = []
    """
    Check first if we have a cached copy
    """
    if pi.cache_file_exists():
        print "INFO: CACHED PARLIAMENT INFO  FILE EXISTS !"
        # if the cache file exists
        # get the parliament info from cache
        if pi.is_cache_full():
            pc_info.parl_info = pi.get_from_cache()
            print "INFO: GETTING PARLIAMENT INFO  FROM CACHE", pc_info
        else:
            process_parliament(pi, cfg)
            if pi.is_cache_full():
                pc_info.parl_info = pi.get_from_cache()
            else:
                print "INFO: PARLIAMENT INFO CACHE IS NOT FULL"
                pc_info.parl_info = None
            #pc_info.parl_info = process_parliament(pi, cfg)
            #print "INFO: PARLIAMENT INFO CACHE IS NOT FULL", pc_info
            # walk some more
    else:
        print "INFO: CACHED FILE DOES NOT EXIST, SEEKING INFO"
        pc_info.parl_info = process_parliament(pi, cfg)
    print "INFOINFO: pc_info ", pc_info.parl_info
    return pc_info

def process_parliament(pi, cfg):
    chambers = find_chambers(pi, cfg)
    for key in chambers.keys():
        file_name = chambers[key]
        if file_name.endswith(".xml"):
            pi.process_xml_file(file_name)
        elif file_name.endswith(".zip"):
            pi.process_zip_file(file_name)
    if pi.is_cache_full():
        return pi.get_from_cache()
    else:
        return None    
    
def find_chambers(pi, cfg):
    """
    Find the 2/3 most recent chamber files required
    """
    import re, ntpath
    pattern = "obj-([0-9]*)-.*\.[xz][mi][lp]$"
    match_parl = re.compile(pattern)
    chamber_type = cfg.chamber_type_name()
    path_to_chamber_folder = os.path.join(cfg.input_folder(), chamber_type)
    chamber_files = __files_by_date(path_to_chamber_folder, "*.*")
    found_chambers = {}
    for f in reversed(chamber_files):
        chamber_file_name = ntpath.basename(f)
        fmatch = match_parl.match(chamber_file_name)
        if fmatch is not None:
            chamber_key = fmatch.groups()[0]
            if chamber_key not in found_chambers:
                found_chambers[chamber_key] = f
            else:
                continue
    return found_chambers
    
""""
def _walk_get_parl_info(piw, cfg):
    # !+BICAMERAL !+FIX_THIS returns a contenttype document, but should
    # instead return the extract from the cached parliament_info.xml document 
    # !+FIXED
    # !+UPDATE(ah,  restrict path to xml_db/chamber - earlier this would sweep the entire
    # XML db folder
    parl_info_path = os.path.join(cfg.input_folder(), cfg.chamber_type_name())
    if os.path.exists(parl_info_path):
        piw.walk( 
             os.path.join(cfg.input_folder(), cfg.chamber_type_name()) 
        )
        if piw.is_cache_full():
            return piw.get_from_cache()
        else:
            return None
    else:
        return None
"""


def param_parl_info(cfg, params):
    """
    Converts it to the transformers expected input form
    """
    linfo = LegislatureInfo(cfg)
    li_parl_params = StringBuilder()
    li_parl_params.append(
        "<parliaments>"
        )
    li_parl_params.append(
           ("<countryCode>%(country_code)s</countryCode>"  
            "<parliament id=\"0\">" 
            "  <identifier>%(identifier)s</identifier>"
            "  <startDate>%(start_date)s</startDate>" 
            "  <electionDate>%(election_date)s</electionDate>" 
            "  <type displayAs=\"National Assembly\">nat_assembly</type>"
            "</parliament>")% 
            {
            "country_code" : linfo.get_country_code(),
            "identifier" : linfo.get_legislature_identifier(),
            "start_date" : linfo.get_legislature_start_date(),
            "election_date" : linfo.get_legislature_election_date()
            }
        )
    for param in params:
        li_parl_params.append(
             ('<parliament id="%(parl_id)s">'
             " <startDate>%(start_date)s</startDate>"
             " <forParliament>%(for_parl)s</forParliament>"
             " <identifier>%(identifier)s</identifier>"
             '<type displayAs="%(type_display)s">%(type)s</type>'
             '<status>%(status)s</status>'
             "</parliament>") %  
             {
              "parl_id" : param["parliament-id"],
              "start_date": param["chamber-start-date"],
              "identifier": param["identifier"],
              "status": param["status"],
              "for_parl": param["for-parliament"],
              "type": param["type"],
              "type_display": param["type_display"]
              }
        )
    li_parl_params.append(
        "</parliaments>"
    )
    print "parl_info = " + li_parl_params.toString()
    return li_parl_params.toString()

def param_type_mappings():
    type_mappings_file = __type_mappings_file()
    type_mappings = open(type_mappings_file, "r").read()
    return type_mappings.encode("UTF-8")

def __type_mapping_element_impl(name, enabled, map_str, logical_mappings):
    if enabled == "true":
        pname = ""
        cname = ""
        if name in logical_mappings.keys():
            pname = typename_to_propercase(logical_mappings[name])
            cname = typename_to_camelcase(logical_mappings[name])
        else:
            pname = typename_to_propercase(name)
            cname = typename_to_camelcase(name)
        return map_str % (
            name, 
            pname, 
            cname
        )
    else:
        return None

def __type_mapping_element(type, map_str, logical_mappings):
    name = type.attributeValue("name")
    enabled = type.attributeValue("enabled")
    return __type_mapping_element_impl(name, enabled, map_str, logical_mappings)

__maps_str__ = '   <map from="%s" uri-name="%s" element-name="%s" />'
def __generate_type_mappings(logical_mappings, types_filter):
    li_map_doc = []
    for type_filter in types_filter:
        type_elem = __type_mapping_element(type_filter,  __maps_str__, logical_mappings)
        if type_elem is not None:
            li_map_doc.append(type_elem)
    return li_map_doc         

def generate_type_mappings(logical_mappings, parser_bungeni_types, parser_pipe_configs):
    li_map_doc = []
    li_map_doc.append('<?xml version="1.0" encoding="UTF-8"?>')
    li_map_doc.append("<!-- AUTO GENERATED type mappings from bungeni to glue types -->")
    li_map_doc.append("<value>")
    map_str = '   <map from="%s" uri-name="%s" element-name="%s" />'

    li_map_doc.extend(
       __generate_type_mappings(
           logical_mappings,
           parser_bungeni_types.get_legislature()
       )
    )
    li_map_doc.extend(
       __generate_type_mappings(
           logical_mappings,
           parser_bungeni_types.get_chambers()
       )
    )
    li_map_doc.extend(
       __generate_type_mappings(
           logical_mappings,
           parser_bungeni_types.get_docs()
       )
    )
    li_map_doc.extend(
       __generate_type_mappings(
           logical_mappings,
           parser_bungeni_types.get_events()
       )
    )
    li_map_doc.extend(
       __generate_type_mappings(
           logical_mappings,
           parser_bungeni_types.get_groups()
       )
    )
    li_map_doc.extend(
       __generate_type_mappings(
           logical_mappings,
           parser_bungeni_types.get_members()
       )
    )

    """
    legislature_type = parser_bungeni_types.get_legislature()
    for leg_type in legislature_type:
        map_elem = __type_mapping_element(leg_type, map_str, logical_mappings)
        if map_elem is not None:
            li_map_doc.append(map_elem)
    chamber_types = parser_bungeni_types.get_chambers()
    for chamber_type in chamber_types:
        map_elem = __type_mapping_element(chamber_type, map_str, logical_mappings)
        if map_elem is not None:
            li_map_doc.append(map_elem)
    doc_types = parser_bungeni_types.get_docs()
    for doc_type in doc_types:
        map_elem = __type_mapping_element(doc_type, map_str, logical_mappings)
        if map_elem is not None:
            li_map_doc.append(map_elem)
    events = parser_bungeni_types.get_events()
    for event in events:
        map_elem = __type_mapping_element(event, map_str, logical_mappings)
        if map_elem is not None:
            li_map_doc.append(map_elem)
    groups = parser_bungeni_types.get_groups()
    for group in groups:
        map_elem = __type_mapping_element(group, map_str, logical_mappings)
        if map_elem is not None:
            li_map_doc.append(map_elem)
    members = parser_bungeni_types.get_members()
    for member in members:
        map_elem = __type_mapping_element(member, map_str, logical_mappings)
        if map_elem is not None:
            li_map_doc.append(map_elem)
    """
    itype_configs = parser_pipe_configs.get_config_internal()
    for itype in itype_configs:
        name = itype.attributeValue("for")
        enabled = "true"
        map_elem = __type_mapping_element_impl(name, enabled, map_str, logical_mappings) 
        if map_elem is not None:
            li_map_doc.append(map_elem) 
    #!+HACK_ALERT(event, doc)
    li_map_doc.append(map_str % ("event", "Event", "event"))
    li_map_doc.append("</value>")
    return ("\n".join(li_map_doc)).encode("UTF-8")

def load_logical_mappings(cfg, parser_bungeni_types):
    logical_mappings = {}
    archetypes = parser_bungeni_types.get_nonbase_archetypes()
    for type in archetypes:
        name = type.attributeValue("name")
        logical = type.attributeValue("archetype")
        logical_mappings[name] = logical
    return logical_mappings
    
    """
    logical_mappings = {}
    parser_bungeni_types.doc_parse()
    ce_types = parser_bungeni_types.get_ce_types_map()
    for ce_type in ce_types:
        name = ce_type.attributeValue("name")
        # namespaced attribute, so use a qualified name
        logical = ce_type.attributeValue(parser_bungeni_types.qname("ce", "type"))
        logical_mappings[name] = logical
    return logical_mappings
    """
    
    '''
    map_parse = ParseLogicalTypesXML(__logical_mappings_file())
    map_parse.doc_parse()
    logical_mappings = {}
    for type_elem in map_parse.get_types():
        name = type_elem.attributeValue("name")
        logical = type_elem.attributeValue("logical")
        logical_mappings[name] = logical
    return logical_mappings
    '''
    

def write_type_mappings(config, parser_bungeni_types, parser_pipe_configs):
    '''
    Generates the type_mappings file
    '''
    logical_mappings = load_logical_mappings(config, parser_bungeni_types)
    type_mappings = generate_type_mappings(logical_mappings, parser_bungeni_types, parser_pipe_configs)
    if type_mappings is not None:
        print "TYPE MAPPINGS = ", type_mappings
        ftype_mappings = codecs.open(__type_mappings_file(), "w", "utf-8")
        ftype_mappings.write(type_mappings)
        ftype_mappings.flush()
        ftype_mappings.close()
        return True
    return False

def types_all_config(config_file):
    cfg = TransformerConfig(config_file)
    # parse the bungeni types.xml file to get all the bungeni types
    parser_bungeni_types = ParseBungeniTypesXML(cfg.types_xml_from_bungeni_custom())
    parser_bungeni_types.doc_parse()
    # parse the pipeline configs file
    parser_pipe_configs = ParsePipelineConfigsXML(__pipeline_configs_file())
    parser_pipe_configs.doc_parse()
    print "Writing type mappings..."
    if write_type_mappings(cfg, parser_bungeni_types, parser_pipe_configs):
        # write pipelines
        print "Writing pipelines ...."
        if write_pipelines(cfg, parser_bungeni_types, parser_pipe_configs):
            return True
    return False    

def __pipeline_element(type, parse_pipe_configs, map_str):
    # get element name
    base_type = type.name
    name = type.attributeValue("name")
    enabled = type.attributeValue("enabled")
    sub_archetype = type.attributeValue("archetype")
    if enabled == "true":
        #use_archetype = base_type
        if sub_archetype is None:
            sub_archetype = ""
        #    use_archetype = sub_archetype
        #     <pipelineConfig for="doc" type="archetype" 
        #         pipeline="configfiles/configs/config_bungeni_parliamentaryitem.xml" /> 
        pipe_config = parse_pipe_configs.get_config_for(base_type)
        # '   <pipeline for="%s" pipeline="%s" archetype="%s" />'
        
        return map_str % (
            name, 
            pipe_config.attributeValue("pipeline"),
            sub_archetype, 
            base_type
        )
    else:
        return None


def generate_pipelines(config, parser_bungeni_types, parser_pipe_configs):
    '''
    Generates the pipelines for available types
    '''
    li_pipe_doc = []
    li_pipe_doc.append('<?xml version="1.0" encoding="UTF-8"?>')
    li_pipe_doc.append("<!-- AUTO GENERATED PIPELINE -->")
    li_pipe_doc.append("<pipelines>")
    map_str = '   <pipeline for="%s" pipeline="%s" archetype="%s" basetype="%s" />'
    types = parser_bungeni_types.get_all()
    for type in types:
        pipe = __pipeline_element(type, parser_pipe_configs, map_str)
        if pipe is not None:
            li_pipe_doc.append(pipe)
    # now generate internal type pipelines
    for ipipe in parser_pipe_configs.get_config_internal():
        type = ipipe.attributeValue("for")
        pipeline = ipipe.attributeValue("pipeline")
        pipe = map_str % (type, pipeline, type, "")
        li_pipe_doc.append(pipe)
    #
    # !+HACK_ALERT (the below is purely a hack to account for the fact that the "event" type is inconsistently described in 
    # bungeni configuration. "event" is an archetype but is explicitly described via an attribute. Additionally when event
    # archetyped events get serialized, they get serialized with an "event" type instead of the specific type name !
    #
    li_pipe_doc.append(map_str % ("event", parser_pipe_configs.get_config_for("event").attributeValue("pipeline"), "event", "doc"))    
    li_pipe_doc.append("</pipelines>")
    return ("\n".join(li_pipe_doc)).encode("UTF-8")


def write_pipelines(config, parser_bungeni_types, parser_pipe_configs):
    pipelines = generate_pipelines(config, parser_bungeni_types, parser_pipe_configs)
    if pipelines is not None:
        print "PIPELINES  = ", pipelines
        fpipes = codecs.open(__pipelines_file(), "w", "utf-8")
        fpipes.write(pipelines)
        fpipes.flush()
        fpipes.close()
        return True
    return False
            
            
def is_exist_running(config_file):
    exist_running = True
    webdaver = None
    try:
        wd_cfg = WebDavConfig(config_file)
        xml_folder = wd_cfg.get_http_server_port() + wd_cfg.get_bungeni_xml_folder()
        webdaver = WebDavClient(
                wd_cfg.get_username(), 
                wd_cfg.get_password(), 
                xml_folder
                )
        webdaver.resource_exists(
            xml_folder
            )
    except Exception, e:
        # silent 
        exist_running = False
    except HttpHostConnectException, e:
        exist_running = False
    finally:
        if webdaver is not None:
            webdaver.shutdown()
    return exist_running
        
    


def languages_info_xml(cfg):
    lang_map = cfg.languages_info()
    from babel import Locale
    allowed_languages = lang_map["allowed_languages"].split(" ")
    li_langs = None
    if len(allowed_languages) > 0:
        li_langs = StringBuilder()
        li_langs.append("<languages>")
        for lang in allowed_languages:
            default_lang = False
            right_to_left = False
            if lang == lang_map["default_language"]:
                default_lang = True
            if lang in lang_map["right_to_left_languages"].split(" "):
                right_to_left = True
            li_langs.append(    
            '<language id="%s" ' % lang 
            )
            if default_lang:
                li_langs.append(
                    ' default="true" '
                )
            if right_to_left:
                li_langs.append(
                    ' rtl="true" '
                )
            locale = Locale(lang)
            if locale is not None:
                li_langs.append(
                    ' english-name="%s"' % locale.english_name
                )
                li_langs.append(
                    ' display-name="%s"' % locale.display_name
                )
            li_langs.append(" />")
        li_langs.append("</languages>")
    if li_langs is None:
        return li_langs
    else:
        return li_langs.toString()

def publish_languages_info_xml(config_file):
    up_stat = None
    webdaver = None
    try :
        cfg = TransformerConfig(config_file)
        xml_lang_info = languages_info_xml(cfg)
        path_to_file = os.path.join(
            cfg.get_temp_files_folder(),
            "lang_info.xml"
            )
        bwriter = BufferedWriter(
            OutputStreamWriter(
                FileOutputStream(path_to_file), "UTF8"
                )
            )
        bwriter.append(xml_lang_info)
        bwriter.flush()
        bwriter.close() 
            
        wd_cfg = WebDavConfig(config_file)
        xml_folder = wd_cfg.get_http_server_port() + wd_cfg.get_bungeni_xml_folder()
        webdaver = WebDavClient(
                wd_cfg.get_username(), 
                wd_cfg.get_password(), 
                xml_folder
                )
        webdaver.reset_remote_folder(
            xml_folder
            )
        up_stat = webdaver.pushFile(path_to_file)
    except Exception,e:
        print "Error while getting languages info", e
    finally:
        if webdaver is not None:
            webdaver.shutdown()
    return up_stat
        
def do_bind_attachments(cfg):
    # first we unzip the attachments using the GenericDirWalkerUNZIP 
    # so we get xml + attachments in a sub-folder
    unzipwalker = GenericDirWalkerUNZIP()
    unzipwalker.walk(cfg.input_folder())
    # Now the files are unzipped in sub-folders - so we process the XML 
    # for the attachments, the attachments are renamed to a unique id
    # and the reference reset in the source document
    sba = SeekBindAttachmentsWalker({"main_config":cfg})
    sba.walk(cfg.input_folder())
    if sba.object_info is not None:
        print COLOR.OKBLUE,"ATT: Found attachment ", COLOR.ENDC
    else:
        return sba.object_info

def do_po_translations(cfg, po_cfg, wd_cfg):
    """ translating .po files """
    print COLOR.OKGREEN + "Translating .po files to i18n xml <catalogue/> format..." + COLOR.ENDC
    pofw = POFilesTranslator({"main_config":cfg, "po_config" : po_cfg, "webdav_config" : wd_cfg})
    pofw.po_to_xml_catalogue()
    print COLOR.OKGREEN + "Completed translations from po to xml !" + COLOR.ENDC
    print COLOR.OKGREEN + "Commencing i18n catalogues upload to eXist-db via WebDav..." + COLOR.ENDC
    pofw.upload_catalogues()
    print COLOR.OKGREEN + "Catalogues uploaded to eXist-db !" + COLOR.ENDC

def do_transform(cfg, params):
    """
    Batch processor for XML documents
    """
    transformer = Transformer(cfg)
    transformer.set_params(params)
    print COLOR.OKGREEN + "Commencing transformations..." + COLOR.ENDC
    pxf = ProcessXmlFilesWalker({"main_config":cfg, "transformer":transformer})
    pxf.walk(cfg.input_folder())
    print COLOR.OKGREEN + "Completed transformations !" + COLOR.ENDC

def do_sync(cfg, wd_cfg):
    print COLOR.OKGREEN + "Syncing with eXist repository..." + COLOR.ENDC
    """ synchronizing xml documents """
    sxw = SyncXmlFilesWalker({"main_config":cfg, "webdav_config" : wd_cfg})

    if not os.path.isdir(cfg.get_temp_files_folder()):
        mkdir_p(cfg.get_temp_files_folder())

    sxw.create_sync_file()
    sxw.walk(cfg.get_xml_output_folder())
    sxw.close_sync_file()
    print COLOR.OKGREEN + "Completed synching to eXist !" + COLOR.ENDC

def webdav_upload(cfg, wd_cfg):
    print COLOR.OKGREEN + "Commencing XML files upload to eXist via WebDav..." + COLOR.ENDC
    """ uploading xml documents """
    # first reset bungeni xmls folder
    webdaver = None
    try:
        webdaver = WebDavClient(wd_cfg.get_username(), wd_cfg.get_password())
        webdaver.reset_remote_folder(wd_cfg.get_http_server_port()+wd_cfg.get_bungeni_xml_folder())
        #webdaver.shutdown()
        # upload xmls at this juncture
        rsu = RepoSyncUploader({"main_config":cfg, "webdav_config" : wd_cfg})
        rsu.upload_files()
        rsu = None
        print COLOR.OKGREEN + "Commencing ATTACHMENT files upload to eXist via WebDav..." + COLOR.ENDC
        """ now uploading found attachments """
        # first reset attachments folder
        webdaver = WebDavClient(wd_cfg.get_username(), wd_cfg.get_password())
        webdaver.reset_remote_folder(wd_cfg.get_http_server_port()+wd_cfg.get_bungeni_atts_folder())
        #webdaver.shutdown()
        # upload attachments at this juncture
        pafw = ProcessedAttsFilesWalker({"main_config":cfg, "webdav_config" : wd_cfg})
        pafw.walk(cfg.get_attachments_output_folder())
        print COLOR.OKGREEN + "Completed uploads to eXist !" + COLOR.ENDC
    except Exception, e:
        print "Exception while uploading via webdav : ", e
    finally:
        if webdaver is not None:
            webdaver.shutdown()
        

def main_po_translate(config_file):
    """
    accepts the --po2xml option to translate .po files to i18n catalogue scheme
    used in the eXist-db
    """
    po_cfg = PoTranslationsConfig(config_file)
    wd_cfg = WebDavConfig(config_file)
    #ensure the tmp folder and its children are there or create them
    __setup_tmp_dirs__(po_cfg)
    do_po_translations(TransformerConfig(config_file), po_cfg, wd_cfg)


def main_transform(config_file):
    """
    process the -transform option by running the transformation
    """
    print "IN MAIN TRANSFORM" , config_file
    cfg = TransformerConfig(config_file)
    # create the output folders
    __setup_cache_dirs__(cfg)
    __setup_output_dirs__(cfg)
    print COLOR.HEADER + "Retrieving parliament information..." + COLOR.ENDC
    # look for the parliament document - and get the info which is used in the
    # following transformations
    # returns a list
    pc_info = get_parl_info(config_file)
    if pc_info == None:
        print COLOR.FAIL, "PARLINFO is NULL"
        sys.exit()
    if pc_info.parl_info is None:
        print COLOR.FAIL, "PARL_INFO is NULL"
        sys.exit()
    if len(pc_info.parl_info) == 0:
        print COLOR.FAIL, "PARLINFO is EMPTY"
        sys.exit()
    print COLOR.OKGREEN,"Retrieved Parliament info...", pc_info, COLOR.ENDC
    print COLOR.OKGREEN + "Seeking attachments..." + COLOR.ENDC
    do_bind_attachments(cfg)
    print COLOR.OKGREEN + "Done with attachments..." + COLOR.ENDC
    print COLOR.HEADER + "Transforming ...." + COLOR.ENDC      
    do_transform(
        cfg,
        {
         "parliament-info" : param_parl_info(cfg, pc_info.parl_info),
         "type-mappings": param_type_mappings()
        } 
        )


def main_sync(config_file):
    wd_cfg = WebDavConfig(config_file)
    do_sync(TransformerConfig(config_file), wd_cfg)


def main_upload(config_file):
    """
    process the --upload option by calling the webdav upload
    """
    wd_cfg = WebDavConfig(config_file)
    webdav_upload(TransformerConfig(config_file), wd_cfg)

def update_refs(config_file):
    wd_cfg = WebDavConfig(config_file)
    print COLOR.OKGREEN + "Commencing Repository updates..." + COLOR.ENDC
    pt = PostTransform({"webdav_config": wd_cfg})
    pt.update()

"""
def list_uniqifier(seq):
    #http://www.peterbe.com/plog/uniqifiers-benchmark
    # wary or RabbitMQ producer giving us duplicates in cases of overwriting a file 
    # pyinotify would register two events of the same thing. So uncool! :@
    seen = set()
    seen_add = seen.add
    return [ x for x in seq if x not in seen and not seen_add(x)]
"""

def publish_parliament_info(config_file, parliament_cache_info):
    cfg = TransformerConfig(config_file)
    xml_parl_info = param_parl_info(cfg, parliament_cache_info.parl_info)
    path_to_file = os.path.join(cfg.get_temp_files_folder(),"legislature_info.xml")
    bwriter = BufferedWriter(
        OutputStreamWriter(
            FileOutputStream(path_to_file), "UTF8"
            )
        )
    bwriter.append(xml_parl_info)
    bwriter.flush()
    bwriter.close() 
    
    wd_cfg = WebDavConfig(config_file)
    xml_folder = wd_cfg.get_http_server_port() + wd_cfg.get_bungeni_xml_folder()
    webdaver = None
    try:
        webdaver = WebDavClient(
                wd_cfg.get_username(), 
                wd_cfg.get_password(), 
                xml_folder
                )
        #already called in language publish
        #webdaver.reset_remote_folder(xml_folder)
        up_stat = webdaver.pushFile(path_to_file)
    except Exception, e:
        print "Error while publishing parliament info", e
    finally:
        if webdaver is not None:
            webdaver.shutdown()
    return up_stat
       

def webdav_reset_folder(wd_cfg, folder):
    webdaver = None
    try:
        webdaver = WebDavClient(wd_cfg.get_username(), wd_cfg.get_password())
        webdaver.reset_remote_folder(wd_cfg.get_http_server_port()+folder)
    except Exception, e:
        print "Error while resetting webdav folder !"
    finally:
        if webdaver is not None:
            webdaver.shutdown()


def rabbitmq_config(config_file):
    cfg = RabbitMqConfig(config_file)
    return cfg
    
    

def post_process_action(config_file, afile):
    '''
    Post processes the files after it has been successfully serialized
    '''
    # get the archive action
    cfg = TransformerConfig(config_file)
    pp_action = cfg.get_postprocess_action()
    if pp_action == "delete":
        delete_file_from_fs(afile)
    elif pp_action == "archive":
        move_file_to_archive(cfg, afile)
    else:
        pass
    

def delete_file_from_fs(afile):
    print "Attempting to remove ", afile
    if os.path.isfile(afile):
        try:
            os.remove(afile)
        except Exception:
            print "Error while attempting to delete file !!", afile
        except IOError:
            print "Error while attempting to delete file !!", afile    


def __create_archive_folder(archive_folder):
    if os.path.exists(archive_folder):
        if os.path.isdir(archive_folder):
            pass
    else:
        try:
            os.makedirs(archive_folder)
        except Exception:
            print "Error while attempting to create archive folder !"
        except IOError:
            print "Error while attempting to create archive folder !"


def move_file_to_archive(cfg, afile):
    print "Attempting to move file to archive", afile
    if os.path.isfile(afile):
        # attempting to move file here
        archive_folder = cfg.get_postprocess_archive()
        __create_archive_folder(archive_folder)
        if os.path.isdir(archive_folder):
            dir_path = os.path.dirname(afile)
            import ntpath
            dir_name = ntpath.basename(dir_path)
            archive_dir_path = os.path.join(archive_folder, dir_name)
            __create_archive_folder(archive_dir_path)
            if os.path.isdir(archive_dir_path):
                shutil.copy2(afile, archive_dir_path)
                delete_file_from_fs(afile)
    else:
        print "Error cannot archive as it is not a file !", afile
            
      
def main_queue(config_file, afile, parliament_cache_info):
    """
    
    Entry Point for Queue invocation, processes one file at a time
    
    Serially processes XML/ZIP files from the message queue and 
    uploads to XML repository. Returns True/False to consumer
        True = Remove from queue
        False = Retain in queue for whatever reason
    
    @param config_file  configuration file
    @param afile        path to the serialized file
    @param parliament_cache_info object of type gen_utils.ParliamentCacheInfo
    @return Boolean 
    """
    print "[checkpoint] got file " + afile
    script_path = os.path.dirname(os.path.realpath(__file__))
    PropertyConfigurator.configure(script_path + File.separator + "log4j.properties")
    # comment above lines to run in emotional mode
    cfg = TransformerConfig(config_file)
    # create the output folders
    __setup_output_dirs__(cfg)
    wd_cfg = WebDavConfig(config_file)
    in_queue = False
    transformer = Transformer(cfg)
    input_map = {
        "parliament-info" : param_parl_info(cfg, parliament_cache_info.parl_info),
        "type-mappings" : param_type_mappings()         
        }
    print "INFOINFO : parliament-info ", input_map["parliament-info"]
    transformer.set_params(input_map)
    cfgs = {
        "main_config":cfg, 
        "transformer":transformer, 
        "webdav_config" : wd_cfg
    }
    pxf = ProcessXmlFilesWalker(cfgs)
    """
    Do Unzipping and Transformations
    """
    import fnmatch
    if os.path.isfile(afile):
        """
        Copy afile to temp_files_folder as working-copy(wc_afile)
        """
        temp_dir = cfg.get_temp_files_folder()
        wc_afile = temp_dir + os.path.basename(afile)
        shutil.copyfile(afile, wc_afile)
        print "[checkpoint] copied working-copy to temp folder"
        
        if fnmatch.fnmatch(afile, "*.zip") and os.path.isfile(wc_afile):
            print "[checkpoint] unzipping archive files"
            unzip = GenericDirWalkerUNZIP()
            temp_dir = cfg.get_temp_files_folder()
            unzip.extractor(afile, temp_dir)
            xml_basename = os.path.basename(wc_afile)
            xml_name = os.path.splitext(xml_basename)[0]
            new_afile = temp_dir + xml_name + ".xml"
            if os.path.isfile(new_afile):
                print "[checkpoint] found the unzipped XML file"
                # if there is an XML file inside then we have process its atts
                # descending upon the extracted folder
                bunparse = ParseBungeniXML(new_afile)
                parse_ok = bunparse.doc_parse()
                if parse_ok == False:
                    # Parsing error return to queue
                    return False
                print "[checkpoint] unzipped file parsed"
                sba = SeekBindAttachmentsWalker(cfgs)
                image_node = bunparse.get_image_file()
                votes_node = bunparse.get_votes_file()
                if (image_node is not None):
                    print "[checkpoint] entered user/group doc path"
                    local_dir = os.path.dirname(afile)
                    print "[checkpoint] processing image/log_data file"
                    origi_name = sba.image_seek_rename(bunparse, temp_dir, True)
                elif (votes_node is not None):
                    print "[checkpoint] we have votes"
                    local_dir = os.path.dirname(afile)
                    print "[checkpoint] processing file with roll_call node"
                    origi_name = sba.votes_seek_rename(bunparse, temp_dir, True)
                else:
                    print "[checkpoint] entered attachments doc path"
                    sba.attachments_seek_rename(bunparse)

                print "[checkpoint] transforming the xml with zipped files"
                info_object = pxf.process_file(new_afile)
                # remove unzipped new_afile & wc_afile from temp_files_folder
                os.remove(new_afile)
                os.remove(wc_afile)
                if info_object[1] == True:
                    in_queue = True
                elif info_object[1] == False:
                    in_queue = False
                    return in_queue
                else:
                    print COLOR.WARNING, "No pipeline defined here ", COLOR.ENDC
                    in_queue = False
                    return in_queue
            else:
                print "[checkpoint] extracted " + new_afile + "] but not found :-J"
                in_queue = True
                return in_queue
        elif fnmatch.fnmatch(afile, "*.xml") and os.path.isfile(wc_afile):
            print "[checkpoint] transforming the xml"
            info_object = pxf.process_file(wc_afile)
            # remove wc_afile from temp_files_folder
            os.remove(wc_afile)
            if info_object[1] == True:
                print "[checkpoint] transformed the xml"
                in_queue = True
            elif info_object[1] == False:
                in_queue = False
                return in_queue
            elif info_object[1] == None:
                # mark parl-information document for removal from message-queue
                in_queue = True
                return in_queue
            else:
                print COLOR.WARNING, "No pipeline defined here ", COLOR.ENDC
                in_queue = False
                return in_queue
        else:
            # ignore any other file type, not interested with them currently...
            print "[" + afile + "] ignoring unprocessable filetype"
            in_queue = True
            return in_queue
    else:
        print "[" + afile + "] not found in filesystem"
        in_queue = True
        return in_queue

    """
    Do sync step
    """
    print "[checkpoint] entering sync"
    
    sxw = SyncXmlFilesWalker(cfgs)
    if not os.path.isdir(cfg.get_temp_files_folder()):
        mkdir_p(cfg.get_temp_files_folder())
    sxw.create_sync_file()
    # reaching here means there is a successfull file
    sync_stat_obj = sxw.sync_file(info_object[0])
    sxw.close_sync_file()
    sxw = None

    print "[checkpoint] exiting sync"
    if sync_stat_obj[0] == True and sync_stat_obj[1] == None:
        # ignore upload -remove from queue
        in_queue = True
        return in_queue
    elif sync_stat_obj[0] == True:
        in_queue = True
    else:
        # eXist not responding?!
        # requeue and try later
        in_queue = False
        return in_queue

    """
    Do uploading to eXist
    """
    print COLOR.OKGREEN + "Uploading XML file(s) to eXist via WebDav..." + COLOR.ENDC
    print "[checkpoint] at", time.localtime(time.time())
    # first reset bungeni xmls folder
    webdav_reset_folder(wd_cfg, wd_cfg.get_bungeni_xml_folder())
    #webdaver = WebDavClient(wd_cfg.get_username(), wd_cfg.get_password())
    #webdaver.reset_remote_folder(wd_cfg.get_http_server_port()+wd_cfg.get_bungeni_xml_folder())
    #webdaver.shutdown()
    rsu = RepoSyncUploader({"main_config":cfg, "webdav_config" : wd_cfg})
    print "[checkpoint] uploading XML file"
    if in_queue == True:
        upload_stat = rsu.upload_file(info_object[0])
        rsu = None
    else:
        rsu = None
        in_queue = False
        return in_queue

    print COLOR.OKGREEN + "Uploading ATTACHMENT file(s) to eXist via WebDav..." + COLOR.ENDC
    
    webdav_reset_folder(wd_cfg, wd_cfg.get_bungeni_atts_folder())
    #webdaver = WebDavClient(wd_cfg.get_username(), wd_cfg.get_password())
    #webdaver.reset_remote_folder(wd_cfg.get_http_server_port()+wd_cfg.get_bungeni_atts_folder())
    #webdaver.shutdown()
    
    # upload attachments at this juncture
    pafw = ProcessedAttsFilesWalker({"main_config":cfg, "webdav_config" : wd_cfg})
    info_obj = pafw.process_atts(cfg.get_attachments_output_folder())
    
    if info_obj == True:
        pafw = None
        in_queue = True
    else:
        pafw = None
        return False
    print COLOR.OKGREEN + "Completed upload to eXist!" + COLOR.ENDC
    # do post-transform
    """
    !+FIX_THIS (ao,8th Aug 2012) PostTransform degenerates and becomes and expensive process 
    over-time temporarily disabled.
    """
    pt = PostTransform({"webdav_config": wd_cfg})
    print "Initiating PostTransform request on eXist-db for URI =>", sync_stat_obj[1]
    info_object = pt.update(str(sync_stat_obj[1]))
    
    if info_object == True:
        in_queue = True
    else:
        in_queue = False
    return in_queue


def main(options):
    """
    Entry point for command line invocation
    """
    # parse command line options if any
    try:
        # first get the configuration file from the command line
        config_file = __parse_options(options, ("-c", "--config"))
        # transform and upload are independent options and can be called individually
        if config_file is not None and len(str(config_file)) > 0 :

            translate = __parse_options(options, ("-p", "--po2xml"))
            if translate is not None:
                main_po_translate(config_file)

            transform = __parse_options(options, ("-t", "--transform"))
            if transform is not None:
                main_transform(config_file)

            sync = __parse_options(options, ("-s", "--synchronize"))
            if sync is not None:
                #perform sync at this juncture
                main_sync(config_file)

            upload = __parse_options(options, ("-u", "--upload"))
            if upload is not None:
                main_upload(config_file)
                # perform post-transform URI reference fixes if any
                update_refs(config_file)
            else:
                print "upload not specified"
        else:
            print COLOR.FAIL," config.ini specified incorrectly !",COLOR.ENDC
    except getopt.error, msg:
        print msg
        print COLOR.FAIL + "There was an exception during startup !" + COLOR.ENDC
        sys.exit(2)
        
        
def __parse_options(options, look_for=()):
    input_arg = None
    for opt,arg in options:
        if opt in look_for:
            input_arg = arg
    return input_arg

if __name__ == "__main_test__":
    l = get_legislature_info("/opt/bungeni/bungeni_apps/config/glue.ini")
    p = get_parl_info("/opt/bungeni/bungeni_apps/config/glue.ini")
    print p


if __name__ == "__main__":
    """
    Five command line parameters are supported
    
      --config=config_file_name - specifies the config file name
      --po2xml - translates po files to xml for i18n in eXisd-db
      --transform - runs a transform
      --synchronize - synchronizes with a xml db
      --upload - uploades to a xml db
    """
    script_path = os.path.dirname(os.path.realpath(__file__))
    if (len(sys.argv) > 1):
        #from org.apache.log4j import PropertyConfigurator
        PropertyConfigurator.configure(script_path + File.separator + "log4j.properties")
        # process input command line options
        options, remainder = getopt.getopt(sys.argv[1:], 
          "c:ptsu",
          ["config=", "po2xml","transform","synchronize","upload"]
        )
        # call main
        main(options)
    else:
        print COLOR.FAIL , " config.ini file must be an input parameter " , COLOR.ENDC
