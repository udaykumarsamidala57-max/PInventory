<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
<title>SRS Admission Enquiry Form(2026-27)</title>

<style>
* { box-sizing: border-box; }

body {
    font-family: "Segoe UI", Arial, sans-serif;
    background: linear-gradient(135deg, #dbeafe, #f0f9ff);
    margin: 0;
    padding: 0;
}

.form-box {
    max-width: 700px;
    width: 95%;
    margin: 20px auto;
    background: #ffffff;
    padding: 18px;
    border-radius: 14px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.15);
}

h2 {
    text-align: center;
    color: #1e40af;
    margin-bottom: 18px;
}

.section-card {
    margin-top: 18px;
    padding: 16px;
    border-radius: 12px;
    background: #f8fafc;
    border: 1px solid #e2e8f0;
}

.section-title {
    font-size: 15px;
    font-weight: bold;
    color: #1e40af;
    margin-bottom: 10px;
    border-left: 5px solid #3b82f6;
    padding-left: 10px;
}

.form-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 12px;
}

.form-field {
    display: flex;
    flex-direction: column;
}

label {
    font-weight: 600;
    font-size: 13px;
    color: #1f2937;
    margin-bottom: 4px;
}

input, select {
    height: 42px;
    padding: 0 12px;
    border-radius: 8px;
    border: 1px solid #cbd5e1;
    font-size: 15px;
    transition: 0.3s;
    background: white;
    width: 100%;
}

input:focus, select:focus {
    border-color: #3b82f6;
    box-shadow: 0 0 0 2px rgba(59,130,246,0.15);
    outline: none;
}

.submit-box {
    text-align: center;
    margin-top: 22px;
}

button {
    padding: 12px 36px;
    font-size: 16px;
    background: linear-gradient(135deg, #2563eb, #1e40af);
    color: white;
    border: none;
    border-radius: 30px;
    cursor: pointer;
    box-shadow: 0 6px 15px rgba(37,99,235,0.4);
    transition: 0.3s;
}

button:hover {
    transform: translateY(-2px);
    box-shadow: 0 10px 25px rgba(37,99,235,0.5);
}

.error-msg { color: red; font-size: 14px; }
.success-msg { color: green; font-size: 14px; }

.logo-box {
    text-align: center;
    margin-bottom: 10px;
}

.logo-box img {
    max-width: 160px;
    width: 100%;
    height: auto;
}
</style>

</head>
<body>

<div class="form-box">
<div class="logo-box">
    <img src="Logo.png" alt="School Logo">
</div>
<h2>📘 Admission Enquiry Form (2026-27)</h2>

<p style="color:#dc2626; font-weight:600;">
⚠️ Please fill all details exactly as per the Birth Certificate / Aadhar Card.
</p>

<form action="SaveEnquiryServlet" method="post" onsubmit="return validateBeforeSubmit();">


<div class="section-card">
<div class="section-title">Student Details</div>
<div class="form-grid">

<div class="form-field">
<label>Student Name *</label>
<input type="text" name="student_name" required>
</div>

<div class="form-field">
<label>Gender *</label>
<select name="gender" required>
<option value="" disabled selected>-- Select Gender --</option>
<option>Male</option>
<option>Female</option>
</select>
</div>

<div class="form-field">
<label>Date of Birth *</label>
<input type="date" name="date_of_birth" id="dob" oninput="calculateAge(); checkEligibility();" required>
</div>

<div class="form-field">
<label>Age (Years, Months, Days) *</label>
<input type="text" name="age" id="age" readonly required>
</div>

<div class="form-field">
<label>Class of Admission *</label>
<select name="class_of_admission" id="classSelect" onchange="checkEligibility();" required>
<option value="" disabled selected>-- Select Class --</option>
<option>Nursery</option>
<option>LKG</option>
<option>UKG</option>
<option>Class 1</option>
<option>Class 2</option><option>Class 3</option>
<option>Class 4</option><option>Class 5</option><option>Class 6</option>
<option>Class 7</option><option>Class 8</option>
<option>Class 9</option>
</select>
<div id="eligibilityMsg" class="error-msg"></div>
</div>

<div class="form-field">
<label>Admission Type *</label>
<select name="admission_type" required>
<option value="" disabled selected>-- Select Admission Type --</option>
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

<div class="form-field"><label>Father Name *</label><input type="text" name="father_name" required></div>
<div class="form-field"><label>Occupation *</label><input type="text" name="father_occupation" required></div>
<div class="form-field"><label>Organization *</label><input type="text" name="father_organization" required></div>

<div class="form-field">
<label>Mobile Number *</label>
<input type="text" name="father_mobile_no" id="father_mobile" maxlength="10" onkeyup="checkMobile(this.value)" required>
<div id="mobileMsg" class="error-msg"></div>
</div>

</div>
</div>


<div class="section-card">
<div class="section-title">Mother Details</div>
<div class="form-grid">

<div class="form-field"><label>Mother Name *</label><input type="text" name="mother_name" required></div>
<div class="form-field"><label>Occupation *</label><input type="text" name="mother_occupation" required></div>
<div class="form-field"><label>Organization *</label><input type="text" name="mother_organization" required></div>

<div class="form-field">
<label>Mobile Number *</label>
<input type="text" name="mother_mobile_no" id="mother_mobile" maxlength="10" onkeyup="checkMobile(this.value)" required>
</div>

</div>
</div>


<div class="section-card">
<div class="section-title">Other Details</div>
<div class="form-grid">
<div class="form-field">
<label>Place From *</label>
<input type="text" name="place_from" required>
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
let notEligible = false;


const CUTOFF_DATE = new Date(2026, 4, 31); 


function calculateAge() {
    let dobValue = document.getElementById("dob").value;
    if (!dobValue) return;

    
    let dob = new Date(dobValue);

    let years = CUTOFF_DATE.getFullYear() - dob.getFullYear();
    let months = CUTOFF_DATE.getMonth() - dob.getMonth();
    let days = CUTOFF_DATE.getDate() - dob.getDate();

    if (days < 0) {
        months--;
        let prevMonth = new Date(CUTOFF_DATE.getFullYear(), CUTOFF_DATE.getMonth(), 0);
        days += prevMonth.getDate();
    }

    if (months < 0) {
        years--;
        months += 12;
    }

    document.getElementById("age").value =
        years + " Years " + months + " Months " + days + " Days";
}



function checkEligibility() {
    let dobValue = document.getElementById("dob").value;
    let cls = document.getElementById("classSelect").value;

    if (!dobValue || !cls) return;

    let dob = new Date(dobValue);

   
    let requiredAge = {
        "Nursery": 3,
        "LKG": 4,
        "UKG": 5,
        "Class 1": 6
    };

    let msg = document.getElementById("eligibilityMsg");

    
    if (requiredAge[cls] === undefined) {
        msg.innerHTML = "ℹ Age eligibility will be verified manually for this class.";
        msg.className = "success-msg";
        document.getElementById("submitBox").style.display = "block";
        notEligible = false;
        return;
    }

    
    let eligibleDate = new Date(
        dob.getFullYear() + requiredAge[cls],
        dob.getMonth(),
        dob.getDate()
    );

    if (eligibleDate > CUTOFF_DATE) {
        msg.innerHTML =
            "❌ Not Eligible for " + cls +
            " (Must complete " + requiredAge[cls] +
            " years on or before 31-05-2026)";
        msg.className = "error-msg";
        document.getElementById("submitBox").style.display = "none";
        notEligible = true;
    } else {
        msg.innerHTML =
            "✅ Eligible for " + cls +
            " (Completed " + requiredAge[cls] +
            " years as on 31-05-2026)";
        msg.className = "success-msg";
        document.getElementById("submitBox").style.display = "block";
        notEligible = false;
    }
}



function checkMobile(mobile) {
    if (mobile.length != 10) return;

    let xhr = new XMLHttpRequest();
    xhr.open("GET", "SaveEnquiryServlet?mobile=" + mobile, true);

    xhr.onreadystatechange = function () {
        if (xhr.readyState == 4 && xhr.status == 200) {
            let response = xhr.responseText.trim();

            if (response === "BLOCK") {
                alert("❌ This mobile number already used 2 times. Cannot submit again!");
                document.getElementById("mobileMsg").innerHTML = 
                    "This mobile number already submitted 2 times. Further submissions are blocked.";
                document.getElementById("submitBox").style.display = "none";
                mobileExists = true;
            }
            else if (response === "2") {
                document.getElementById("mobileMsg").innerHTML = 
                    "⚠ This mobile number already used 2 times. This is the LAST allowed submission.";
                document.getElementById("submitBox").style.display = "block";
                mobileExists = false;
            }
            else if (response === "1") {
                document.getElementById("mobileMsg").innerHTML = 
                    "ℹ This mobile number already used once. You can submit one more time.";
                document.getElementById("submitBox").style.display = "block";
                mobileExists = false;
            }
            else {
                document.getElementById("mobileMsg").innerHTML = "";
                document.getElementById("submitBox").style.display = "block";
                mobileExists = false;
            }
        }
    };
    xhr.send();
}



function validateBeforeSubmit() {
    if (mobileExists || notEligible) {
        alert("Please fix errors before submitting!");
        return false;
    }
    return true;
}
</script>


</body>
</html>
