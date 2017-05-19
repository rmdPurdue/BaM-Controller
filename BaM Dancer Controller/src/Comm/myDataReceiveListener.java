/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package Comm;

import com.digi.xbee.api.listeners.IDataReceiveListener;
import com.digi.xbee.api.models.XBeeMessage;

/**
 *
 * @author Rich Dionne <rdionne@purdue.edu>
 */
public class myDataReceiveListener implements IDataReceiveListener {
    
    private String message;

    /*
    * Data reception callback
    */    
    
    @Override
    public void dataReceived(XBeeMessage xbeeMessage) {
        String address = xbeeMessage.getDevice().get64BitAddress().toString();
        byte[] dataString = xbeeMessage.getData();
        System.out.println("Received data from " + address);
        for(byte data:dataString) {
            System.out.println((int)data);
        }
    }
}
