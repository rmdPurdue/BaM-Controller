/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package BaMDancerHub;

import MVC.*;
import com.digi.xbee.api.exceptions.XBeeException;
import java.net.UnknownHostException;
/**
 *
 * @author Rich Dionne <rdionne@purdue.edu>
 */
public class BaMDancerHub {

    /**
     * @param args the command line arguments
     * @throws com.digi.xbee.api.exceptions.XBeeException
     * @throws java.lang.InterruptedException
     * @throws java.net.UnknownHostException
     */
    public static void main(String[] args) throws XBeeException, InterruptedException, UnknownHostException {
            
    // Create model and view
    BaMDancerHubView view = new BaMDancerHubView();
    BaMDancerHubModel model = new BaMDancerHubModel();

    // Create controller and connect model and view to it
    BaMDancerHubController controller = new BaMDancerHubController();
    controller.addModel(model);
    controller.addView(view);
    
    // Initialize the model
    controller.initModel();
    
    // Tell model about view
    model.addObserver(view);
    
    // Connect controller to view
    view.addController(controller);
    
    // Start application
    controller.startApplication();
    }
    
}
