package com.bean;

import java.sql.Date;

public class IndentItems {
    private int id;
    private String indentNo;
    private Date indentDate;
    private String itemName;
    private double qty;
    private String department;
    private String requestedBy;
    private String purpose;
    private String istatus;
    private String istatusApprove;
    private String status;

    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getIndentNo() { return indentNo; }
    public void setIndentNo(String indentNo) { this.indentNo = indentNo; }

    public Date getIndentDate() { return indentDate; }
    public void setIndentDate(Date indentDate) { this.indentDate = indentDate; }

    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }

    public double getQty() { return qty; }
    public void setQty(double qty) { this.qty = qty; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getRequestedBy() { return requestedBy; }
    public void setRequestedBy(String requestedBy) { this.requestedBy = requestedBy; }

    public String getPurpose() { return purpose; }
    public void setPurpose(String purpose) { this.purpose = purpose; }

    public String getIstatus() { return istatus; }
    public void setIstatus(String istatus) { this.istatus = istatus; }

    public String getIstatusApprove() { return istatusApprove; }
    public void setIstatusApprove(String istatusApprove) { this.istatusApprove = istatusApprove; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
