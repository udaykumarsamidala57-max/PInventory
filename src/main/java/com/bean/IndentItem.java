package com.bean;

public class IndentItem {
    private int itemId;
    private String name;
    private double qty;
    private String purpose;
    private String uom;

    public IndentItem(int itemId, String name, double qty, String purpose, String uom) {
        this.itemId = itemId;
        this.name = name;
        this.qty = qty;
        this.purpose = purpose;
        this.uom = uom;
    }

    public int getItemId() { return itemId; }
    public String getName() { return name; }
    public double getQty() { return qty; }
    public String getPurpose() { return purpose; }
    public String getUom() { return uom; }
}
