/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package BaMDancerHub;

/**
 *
 * @author Rich Dionne <rdionne@purdue.edu>
 */
public class Dancer {
    
    int level[] = new int[20];
    long macAddress;
    String addressString;
    String name;
    
    public Dancer(String newName) {
        name = newName;
        for(int i = 0; i < 20; i++) {
            level[i] = 0;
            macAddress = 0;
            addressString = null;
        }
    }
        
    public void setMacAddress(long value) {
        macAddress = value;
    }
    
    public long getMacAddress() {
        return macAddress;
    }
    
    public void setLevel(int index, int value) {
        level[index] = value;
    }
    
    public int getLevel(int index) {
        return level[index];
    }
    
    public void setStringAddress(String addr) {
        addressString = addr;
    }
    
    public String getStringAddr() {
        return addressString;
    }
    
    public String getName() {
        return name;
    }
}
