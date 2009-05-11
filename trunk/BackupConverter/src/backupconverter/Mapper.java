package backupconverter;


import backupconverter.backup.Collection;
import backupconverter.backup.Item;
import backupconverter.backup.Resource;

/**
 * @author Adam Retter <adam.retter@googlemail.com>
 * @version 1.0
 */
public interface Mapper
{
    public boolean shouldMap(Item item);

    public String mapPath(Collection col);

    public String mapPath(Resource res);


}
