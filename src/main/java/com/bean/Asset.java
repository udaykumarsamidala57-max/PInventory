package com.bean;

import java.io.Serializable;
import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;

public class Asset implements Serializable {
    private static final long serialVersionUID = 1L;

    private int assetId;
    private String assetCode;
    private String assetName;
    private Integer categoryId;
    private Integer subcategoryId;
    private String vendorName;
    private String brand;
    private String modelNumber;
    private String serialNumber;
    private Date purchaseDate;
    private BigDecimal purchaseCost;
    private Date warrantyExpiry;
    private String depreciationMethod;
    private Integer usefulLifeYears;
    private BigDecimal salvageValue;
    private String assetStatus;
    private String qrCode;
    private String description;
    private Timestamp createdAt;

    // Default Constructor
    public Asset() {}

    // Getters and Setters
    public int getAssetId() { return assetId; }
    public void setAssetId(int assetId) { this.assetId = assetId; }

    public String getAssetCode() { return assetCode; }
    public void setAssetCode(String assetCode) { this.assetCode = assetCode; }

    public String getAssetName() { return assetName; }
    public void setAssetName(String assetName) { this.assetName = assetName; }

    public Integer getCategoryId() { return categoryId; }
    public void setCategoryId(Integer categoryId) { this.categoryId = categoryId; }

    public Integer getSubcategoryId() { return subcategoryId; }
    public void setSubcategoryId(Integer subcategoryId) { this.subcategoryId = subcategoryId; }

    public String getVendorName() { return vendorName; }
    public void setVendorName(String vendorName) { this.vendorName = vendorName; }

    public String getBrand() { return brand; }
    public void setBrand(String brand) { this.brand = brand; }

    public String getModelNumber() { return modelNumber; }
    public void setModelNumber(String modelNumber) { this.modelNumber = modelNumber; }

    public String getSerialNumber() { return serialNumber; }
    public void setSerialNumber(String serialNumber) { this.serialNumber = serialNumber; }

    public Date getPurchaseDate() { return purchaseDate; }
    public void setPurchaseDate(Date purchaseDate) { this.purchaseDate = purchaseDate; }

    public BigDecimal getPurchaseCost() { return purchaseCost; }
    public void setPurchaseCost(BigDecimal purchaseCost) { this.purchaseCost = purchaseCost; }

    public Date getWarrantyExpiry() { return warrantyExpiry; }
    public void setWarrantyExpiry(Date warrantyExpiry) { this.warrantyExpiry = warrantyExpiry; }

    public String getDepreciationMethod() { return depreciationMethod; }
    public void setDepreciationMethod(String depreciationMethod) { this.depreciationMethod = depreciationMethod; }

    public Integer getUsefulLifeYears() { return usefulLifeYears; }
    public void setUsefulLifeYears(Integer usefulLifeYears) { this.usefulLifeYears = usefulLifeYears; }

    public BigDecimal getSalvageValue() { return salvageValue; }
    public void setSalvageValue(BigDecimal salvageValue) { this.salvageValue = salvageValue; }

    public String getAssetStatus() { return assetStatus; }
    public void setAssetStatus(String assetStatus) { this.assetStatus = assetStatus; }

    public String getQrCode() { return qrCode; }
    public void setQrCode(String qrCode) { this.qrCode = qrCode; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
    
    private String categoryName;

 // Add these methods
 public String getCategoryName() { 
     return categoryName; 
 }
 public void setCategoryName(String categoryName) { 
     this.categoryName = categoryName; 
 }
//Add this alongside categoryName inside com.bean.Asset
private String subcategoryName;

public String getSubcategoryName() { return subcategoryName; }
public void setSubcategoryName(String subcategoryName) { this.subcategoryName = subcategoryName; }
}