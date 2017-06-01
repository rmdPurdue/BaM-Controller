/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package MVC;

import BaMDancerHub.Dancer;
import Comm.OSCHandler;
import Comm.XBeeHandler;
import com.digi.xbee.api.models.XBeeMessage;
import java.util.ArrayList;
import java.net.*;

/**
 *
 * @author Rich Dionne <rdionne@purdue.edu>
 */
public class BaMDancerHubModel extends java.util.Observable {
    
    ArrayList<Dancer> dancers = new ArrayList<>();
    ArrayList<InetAddress> remoteHosts = new ArrayList<>();
    XBeeHandler xbeeHandler = new XBeeHandler();
    OSCHandler oscHandler = new OSCHandler();
    Thread xbeeThread = new Thread(xbeeHandler, "XBee Thread");
    Thread oscThread = new Thread(oscHandler, "OSC Thread");

    public void addDancer(String name, long address) {
        Dancer dancer = new Dancer(name);
        dancer.setMacAddress(address);
        dancers.add(dancer);
    }
    
    public void startXbee() {
        xbeeThread.start();
    }
    
    public void parseXbeeMessage() throws InterruptedException {
        XBeeMessage message = xbeeHandler.dequeueMessage();
        if(message!=null) {
            String addressString = message.getDevice().get64BitAddress().toString();
            byte[] data = message.getData();
            long address = hex2Long(addressString);
            Dancer theDancer;
            for(Dancer dancer:dancers) {
                if(dancer.getMacAddress() == address) {
                    for(int i = 0; i < data.length; i++) {
                        dancer.setLevel(i, data[i]);
                    }
                }
            }
        }
    }
    
    public void generateOSCBundles() throws UnknownHostException {
        InetAddress localHost = InetAddress.getByAddress(new byte[] {127,0,0,1});
        remoteHosts.add(localHost);
        oscHandler.setHostList(remoteHosts);
        oscHandler.setDancerList(dancers);
        System.out.println("Start generating OSC.");
        oscThread.start();
    }
    
    private long hex2Long(String addressString) {
        long address = 0;
        String digits = "0123456789ABCDEF";
        addressString = addressString.toUpperCase();
        for(int i = 0; i < addressString.length(); i++) {
            char c = addressString.charAt(i);
            long d = digits.indexOf(c);
            address = 16 * address + d;
        }
        return address;
    }
}