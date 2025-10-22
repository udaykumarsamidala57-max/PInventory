package com.bean;

public class Indent {
    private int itemId;
    private String name;
    private double qty;
    private String purpose;
    private String uom;
    private double stock; // ✅ new field

    public Indent(int itemId, String name, double qty, String purpose, String uom) {
        this.itemId = itemId;
        this.name = name;
        this.qty = qty;
        this.purpose = purpose;
        this.uom = uom;
    }

    // Getters & setters
    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public double getQty() { return qty; }
    public void setQty(double qty) { this.qty = qty; }

    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }

    public String getUom() { return uom; }
    public void setUom(String uom) { this.uom = uom; }

    public double getStock() { return stock; }
    public void setStock(double stock) { this.stock = stock; }
}
