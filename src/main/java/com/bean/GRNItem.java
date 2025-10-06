package com.bean;

public class GRNItem {
    private int poItemId;         // Purchase Order Item ID
    private int itemId;           // Item Master ID
    private String description;   // Item description
    private double orderedQty;    // Ordered quantity
    private double alreadyReceived; // Quantity already received

    // Default Constructor
    public GRNItem() {}

    // Parameterized Constructor
    public GRNItem(int poItemId, int itemId, String description, double orderedQty, double alreadyReceived) {
        this.poItemId = poItemId;
        this.itemId = itemId;
        this.description = description;
        this.orderedQty = orderedQty;
        this.alreadyReceived = alreadyReceived;
    }

    // Getters and Setters
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
    public void setOrderedQty(double orderedQty) {
        this.orderedQty = orderedQty;
    }

    public double getAlreadyReceived() {
        return alreadyReceived;
    }
    public void setAlreadyReceived(double alreadyReceived) {
        this.alreadyReceived = alreadyReceived;
    }

    // Utility for debugging
    @Override
    public String toString() {
        return "GRNItem{" +
                "poItemId=" + poItemId +
                ", itemId=" + itemId +
                ", description='" + description + '\'' +
                ", orderedQty=" + orderedQty +
                ", alreadyReceived=" + alreadyReceived +
                '}';
    }
}
