package com.bean;

public class GRNItem {
    private int poItemId;
    private int itemId;
    private String description;
    private double orderedQty;
    private double alreadyReceived;

    public GRNItem() {}

    public int getPoItemId() {
        return poItemId;
    }
    public void setPoItemId(int poItemId) {
        this.poItemId = poItemId;
    }

    public int getItemId() {
        return itemId;
    }
    public void setItemId(int itemId) {
        this.itemId = itemId;
    }

    public String getDescription() {
        return description;
    }
    public void setDescription(String description) {
        this.description = description;
    }

    public double getOrderedQty() {
        return orderedQty;
    }
    public void setOrderedQty(double d) {
        this.orderedQty = d;
    }

    public double getAlreadyReceived() {
        return alreadyReceived;
    }
    public void setAlreadyReceived(double alreadyReceived) {
        this.alreadyReceived = alreadyReceived;
    }
}
