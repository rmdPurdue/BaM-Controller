/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package MVC;

import java.util.Queue;
import java.util.concurrent.ArrayBlockingQueue;
import BaMDancerHub.Dancer;
import Comm.myDataReceiveListener;
import com.digi.xbee.api.XBeeDevice;
import com.digi.xbee.api.exceptions.XBeeException;
import java.util.ArrayList;
import java.util.concurrent.Future;

/**
 *
 * @author Rich Dionne <rdionne@purdue.edu>
 */
public class BaMDancerHubModel extends java.util.Observable {
    
    XBeeDevice myXbee;
    Queue<Future<String>> messageQueue = new ArrayBlockingQueue<>(5);
    ArrayList<Dancer> dancers = new ArrayList<>();

    /**
     *
     * @throws com.digi.xbee.api.exceptions.XBeeException
     */
    public void startXBee() throws XBeeException {
        //myXbee = new XBeeDevice("COM3", 9600);
        myXbee.open();
        myXbee.addDataListener(new myDataReceiveListener());
    }
    
    public void addDancer(String name) {
        dancers.add(new Dancer(name));
    }
    
//    public void startXBeeListening() {
//        ThreadPoolExecutor executor = (ThreadPoolExecutor) Executors.newFixedThreadPool(2);
//        Future<String> result = executor.submit(myXbee);
//        messageQueue.offer(executor.submit(myXbee));
//    }
    
//    public void parseMessage() throws InterruptedException, ExecutionException {
//        Future<String> futureMessage = messageQueue.remove();
//        String message = futureMessage.get();
//        String[] chunks = message.split(":");
//        String address = chunks[0];
//        String data = chunks[1];
//    }
}