package com.bean;

import java.sql.Date;

public class Indentlist {
    private int indentId;
    private String indentNo;
    private Date indentDate;
    private String itemName;
    private double qty;
    private String uom;
    private String department;
    private String requestedBy;
    private String purpose;
    private String status;
    private java.sql.Date Iapprovevdate;
    private java.sql.Date Fapprovevdate;

    // Getters and Setters
    public int getIndentId() { return indentId; }
    public void setIndentId(int indentId) { this.indentId = indentId; }

    public String getIndentNo() { return indentNo; }
    public void setIndentNo(String indentNo) { this.indentNo = indentNo; }

    public Date getIndentDate() { return indentDate; }
    public void setIndentDate(Date indentDate) { this.indentDate = indentDate; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public double getQty() { return qty; }
    public void setQty(double qty) { this.qty = qty; }

    public String getUom() { return uom; }
    public void setUom(String uom) { this.uom = uom; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getRequestedBy() { return requestedBy; }
    public void setRequestedBy(String requestedBy) { this.requestedBy = requestedBy; }

    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public Date getIapprovevdate() { return Iapprovevdate; }
    public void setIapprovevdate(Date date) { this.Iapprovevdate = date; }

    public Date getFapprovevdate() { return Fapprovevdate; }
    public void setFapprovevdate(Date date) { this.Fapprovevdate = date; }
}
