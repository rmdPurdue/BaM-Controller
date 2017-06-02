/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package MVC;

import com.digi.xbee.api.exceptions.XBeeException;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.net.UnknownHostException;

/**
 *
 * @author Rich Dionne <rdionne@purdue.edu>
 */
public class BaMDancerHubController implements ActionListener {
    
    private BaMDancerHubModel model;
    private BaMDancerHubView view;
    
    // Create the controller
    public void BaMDancerHubController(BaMDancerHubView view, BaMDancerHubModel model) {
        this.view = view;
        this.model = model;
    }
    
    // Connect model to controller
    public void addModel(BaMDancerHubModel model) {
        this.model = model;
    }
    
    // Connect view to controller
    public void addView(BaMDancerHubView view) {
        this.view  = view;
    }
    
    // Initialize the model
    public void initModel() {
        
    }

    @Override
    public void actionPerformed(ActionEvent ae) {
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }
    
    public void startApplication() throws XBeeException, InterruptedException, UnknownHostException {
        view.setVisible(true);
        model.startXbee();
        Thread.sleep(1000);
        model.addDancer("Dancer1",1234567890);
        model.parseXbeeMessage();
        model.generateOSCBundles();
    }
}
