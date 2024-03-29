package org.bungeni.exist.query;

import java.io.IOException;
import javax.xml.parsers.ParserConfigurationException;
import org.apache.commons.httpclient.NameValuePair;
import org.apache.commons.httpclient.methods.GetMethod;
import org.apache.commons.httpclient.methods.PostMethod;
import org.junit.Test;
import org.xml.sax.SAXException;

/**
 * Test harness for Bungeni Query XQuery REST API Error Codes
 * http://localhost:8088/db/bungeni/query/query.xql
 *
 * @author Adam Retter <adam.retter@googlemail.com>
 * @version 1.0
 */
public class QueryErrorTest extends AbstractErrorTest
{
    @Test
    public void no_action() throws IOException, ParserConfigurationException, SAXException
    {
        final String expectedErrorCode = "UNKNAC0001";
        final String expectedErrorMessage = getErrorMessageForErrorCode(expectedErrorCode);

        GetMethod get = new GetMethod(REST.PACKAGE_URL);

        testErrorResponse(get, expectedErrorCode, expectedErrorMessage);
    }

    @Test
    public void list_components_but_no_uri() throws IOException, ParserConfigurationException, SAXException
    {
        final String expectedErrorCode = "MIDULC0001";
        final String expectedErrorMessage = getErrorMessageForErrorCode(expectedErrorCode);

        GetMethod get = new GetMethod(REST.PACKAGE_URL);
        get.setQueryString(new NameValuePair[]{
            new NameValuePair("action", "list-components")
        });
        
        testErrorResponse(get, expectedErrorCode, expectedErrorMessage);
    }

    @Test
    public void list_attachments_but_no_uri() throws IOException, ParserConfigurationException, SAXException
    {
        final String expectedErrorCode = "MIDULA0001";
        final String expectedErrorMessage = getErrorMessageForErrorCode(expectedErrorCode);

        GetMethod get = new GetMethod(REST.PACKAGE_URL);
        get.setQueryString(new NameValuePair[]{
            new NameValuePair("action", "list-attachments")
        });

        testErrorResponse(get, expectedErrorCode, expectedErrorMessage);
    }
}
