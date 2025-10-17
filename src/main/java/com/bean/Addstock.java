package com.bean;

public class Addstock {
    private int itemId;
    private String category;
    private String subCategory;
    private String itemName;
    private String uom;
    private double stockQty;

    public int getItemId() { return itemId; }
    public void setItemId(int itemId) { this.itemId = itemId; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getSubCategory() { return subCategory; }
    public void setSubCategory(String subCategory) { this.subCategory = subCategory; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public String getUom() { return uom; }
    public void setUom(String uom) { this.uom = uom; }

    public double getStockQty() { return stockQty; }
    public void setStockQty(double stockQty) { this.stockQty = stockQty; }
}
