package com.indent.bean;

import java.math.BigDecimal;

public class InventoryBean {
    private int itemId;
    private String itemName;
    private String uom;
    private double availableQuantity;
    private BigDecimal price = BigDecimal.ZERO;

    public InventoryBean() { }

    public InventoryBean(int itemId, String itemName, String uom, double availableQuantity, BigDecimal price) {
        this.itemId = itemId;
        this.itemName = itemName;
        this.uom = uom;
        this.availableQuantity = availableQuantity;
        this.price = price == null ? BigDecimal.ZERO : price;
    }

    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }
    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }
    public String getUom() { return uom; }
    public void setUom(String uom) { this.uom = uom; }
    public double getAvailableQuantity() { return availableQuantity; }
    public void setAvailableQuantity(double availableQuantity) { this.availableQuantity = availableQuantity; }
    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price == null ? BigDecimal.ZERO : price; }
}
