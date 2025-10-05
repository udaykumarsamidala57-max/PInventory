package com.bean;

import java.util.List;

public class PO {
    private String poNumber;
    private String poDate;
    private String vendorName;
    private double totalAmount;
    private String approval;

    private List<POItems> items;  // One PO can have many items

    public String getPoNumber() { return poNumber; }
    public void setPoNumber(String poNumber) { this.poNumber = poNumber; }

    public String getPoDate() { return poDate; }
    public void setPoDate(String poDate) { this.poDate = poDate; }

    public String getVendorName() { return vendorName; }
    public void setVendorName(String vendorName) { this.vendorName = vendorName; }

    public double getTotalAmount() { return totalAmount; }
    public void setTotalAmount(double totalAmount) { this.totalAmount = totalAmount; }

    public String getApproval() { return approval; }
    public void setApproval(String approval) { this.approval = approval; }

    public List<POItems> getItems() { return items; }
    public void setItems(List<POItems> items) { this.items = items; }
}
