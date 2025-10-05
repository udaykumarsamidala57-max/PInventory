package com.bean;

public class POItems {
    private int id;
    private String indentNo;   // maps to po_no
    private int itemId;        // FK to items table
    private String itemName;   // for display only
    private double qty;
    private double rate;
    private double discountPercent;
    private double gstPercent;
    private double balanceQty; // ✅ new field
    
    
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getIndentNo() { return indentNo; }
    public void setIndentNo(String indentNo) { this.indentNo = indentNo; }

    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public double getQty() { return qty; }
    public void setQty(double d) { this.qty = d; }

    public double getRate() { return rate; }
    public void setRate(double rate) { this.rate = rate; }

    public double getDiscountPercent() { return discountPercent; }
    public void setDiscountPercent(double discountPercent) { this.discountPercent = discountPercent; }

    public double getGstPercent() { return gstPercent; }
    public void setGstPercent(double gstPercent) { this.gstPercent = gstPercent; }

    public double getBalanceQty() { return balanceQty; }
    public void setBalanceQty(double balanceQty) { this.balanceQty = balanceQty; }
    
    private double receivedQty;

    public double getReceivedQty() { return receivedQty; }
    public void setReceivedQty(double receivedQty) { this.receivedQty = receivedQty; }
    
    private double tobereceived;
    public double gettobeReceivedQty() {  return qty - receivedQty;  }
    public void settobeReceivedQty(double tobereceived) { this.tobereceived = tobereceived; }
}
