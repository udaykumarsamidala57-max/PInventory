<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
<title>Admission Enquiry Form</title>

<link rel="stylesheet" href="css/enquiry.css">

<style>
.error-msg {
    color: red;
    font-size: 14px;
}
</style>

</head>
<body>

<div class="form-box">
<h2>📘 Admission Enquiry Form</h2>

<form action="SaveEnquiryServlet" method="post" onsubmit="return validateBeforeSubmit();">

<!-- Student Details -->
<div class="section-card">
    <div class="section-title">Student Details</div>
    <div class="form-grid">

        <div class="form-field">
            <label>Student Name *</label>
            <input type="text" name="student_name" required>
        </div>

        <div class="form-field">
            <label>Gender</label>
            <select name="gender">
                <option value="">-- Select Gender --</option>
                <option>Male</option>
                <option>Female</option>
            </select>
        </div>

        <div class="form-field">
            <label>Date of Birth</label>
            <input type="date" name="date_of_birth" id="dob" oninput="calculateAge()">
        </div>

        <div class="form-field">
            <label>Age (Years, Months, Days)</label>
            <input type="text" name="age" id="age" readonly>
        </div>

        <div class="form-field">
            <label>Class of Admission</label>
            <select name="class_of_admission">
                <option value="">-- Select Class --</option>
                <option>LKG</option>
                <option>UKG</option>
                <option>Class 1</option>
                <option>Class 2</option>
                <option>Class 3</option>
                <option>Class 4</option>
                <option>Class 5</option>
                <option>Class 6</option>
                <option>Class 7</option>
                <option>Class 8</option>
            </select>
        </div>

        <div class="form-field">
            <label>Admission Type</label>
            <select name="admission_type">
                <option value="">-- Select Admission Type --</option>
                <option>Dayscholar</option>
                <option>Residential</option>
                <option>Semi Residential</option>
            </select>
        </div>

    </div>
</div>


<div class="section-card">
    <div class="section-title">Father Details</div>
    <div class="form-grid">

        <div class="form-field">
            <label>Father Name</label>
            <input type="text" name="father_name">
        </div>

        <div class="form-field">
            <label>Occupation</label>
            <input type="text" name="father_occupation">
        </div>

        <div class="form-field">
            <label>Organization</label>
            <input type="text" name="father_organization">
        </div>

        <div class="form-field">
            <label>Mobile Number</label>
            <input type="text" name="father_mobile_no" id="father_mobile" maxlength="10" onkeyup="checkMobile(this.value)">
            <div id="mobileMsg" class="error-msg"></div>
        </div>

    </div>
</div>


<div class="section-card">
    <div class="section-title">Mother Details</div>
    <div class="form-grid">

        <div class="form-field">
            <label>Mother Name</label>
            <input type="text" name="mother_name">
        </div>

        <div class="form-field">
            <label>Occupation</label>
            <input type="text" name="mother_occupation">
        </div>

        <div class="form-field">
            <label>Organization</label>
            <input type="text" name="mother_organization">
        </div>

        <div class="form-field">
            <label>Mobile Number</label>
            <input type="text" name="mother_mobile_no" id="mother_mobile" maxlength="10" onkeyup="checkMobile(this.value)">
        </div>

    </div>
</div>


<div class="section-card">
    <div class="section-title">Other Details</div>
    <div class="form-grid">

        <div class="form-field">
            <label>Segment</label>
            <select name="segment">
                <option value="">-- Select Segment --</option>
                <option>General</option>
                <option>SMIORE</option>
                <option>SVPS</option>
                <option>SVPSGEN</option>
                <option>RTE</option>
            </select>
        </div>

        <div class="form-field">
            <label>Place From</label>
            <input type="text" name="place_from">
        </div>

    </div>
</div>

<div class="submit-box" id="submitBox">
    <button type="submit" id="submitBtn">Submit Enquiry</button>
</div>

</form>
</div>

<script>
let mobileExists = false;


function calculateAge() {
    let dobValue = document.getElementById("dob").value;
    if (!dobValue) {
        document.getElementById("age").value = "";
        return;
    }

    let dob = new Date(dobValue);
    let today = new Date();

    let years = today.getFullYear() - dob.getFullYear();
    let months = today.getMonth() - dob.getMonth();
    let days = today.getDate() - dob.getDate();

    if (days < 0) {
        months--;
        let prevMonth = new Date(today.getFullYear(), today.getMonth(), 0);
        days += prevMonth.getDate();
    }

    if (months < 0) {
        years--;
        months += 12;
    }

    document.getElementById("age").value = years + " Years " + months + " Months " + days + " Days";
}


function checkMobile(mobile) {

    if (mobile.length != 10) {
        resetSubmit();
        return;
    }

    let xhr = new XMLHttpRequest();
    xhr.open("GET", "SaveEnquiryServlet?mobile=" + mobile, true);

    xhr.onreadystatechange = function () {
        if (xhr.readyState == 4 && xhr.status == 200) {

            let response = xhr.responseText.trim();

            if (response === "EXISTS") {

                alert("⚠ This mobile number is already submitted!");

                document.getElementById("mobileMsg").innerHTML = "This mobile number already exists!";
                document.getElementById("submitBox").style.display = "none";
                mobileExists = true;

            } else {

                document.getElementById("mobileMsg").innerHTML = "";
                document.getElementById("submitBox").style.display = "block";
                mobileExists = false;
            }
        }
    };

    xhr.send();
}


function resetSubmit() {
    document.getElementById("submitBox").style.display = "block";
    document.getElementById("mobileMsg").innerHTML = "";
    mobileExists = false;
}


function validateBeforeSubmit() {
    if (mobileExists) {
        alert("This mobile number already exists!");
        return false;
    }
    return true;
}
</script>

</body>
</html>
