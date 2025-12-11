# Assessment Summary

## Overview
This repository contains a complete **1-hour technical skills assessment** for DevOps/Software Engineering candidates. It evaluates diagnostic skills, C# development, and PowerShell scripting.

## Files Created/Updated

### For Candidates
- **`README.md`** - Main assessment document with all three questions, instructions, and success criteria

### For Interviewers (in `AssessorGuide/` folder)
- **`SOLUTIONS.md`** - Complete solutions guide with scoring rubric
- **`INTERVIEWER_SETUP.md`** - Pre-interview setup checklist and troubleshooting
- **`ASSESSMENT_SUMMARY.md`** (this file) - Quick reference
- **`README.md`** - Instructions for removing this folder before sharing

**⚠️ IMPORTANT:** Delete the `AssessorGuide/` folder before forking or sharing with candidates.

## The Three Questions

### Question 1: Diagnose API Failure Using Application Insights (20 min)
**Skill:** Diagnostic skills, reading logs, understanding configuration

**Bug Location:** `Api/appsettings.json` line 10  
**Bug:** Database name has typo: `sqldb-tfls-d4a635oijzpb` (missing 'c' at end)  
**Impact:** API fails to connect to database

**Solution:** Either:
1. Fix the typo in `appsettings.json`, OR
2. Modify `Program.cs` to use `GetConnectionString("TflSchoolApiContext")` which has correct value in `appsettings.Development.json`

**Verification:** API starts successfully, `/api/Students` returns HTTP 200

---

### Question 2: Fix C# Logic Error (20 min)
**Skill:** Code reading, debugging, C# fundamentals

**Bug Location:** `Models/Models/Student.cs` line 19  
**Bug:** Loop uses assignment (`=`) instead of accumulation (`+=`)  
**Impact:** Total credits shows only last enrollment's credits (3) instead of sum (9)

**Solution:**
```csharp
// Change from:
totalCredits = (int)enrollment.Course.Credits;

// To:
totalCredits += enrollment?.Course?.Credits ?? 0;
```

**Verification:** Student "Carson Alexander" shows 9 total credits

---

### Question 3: Fix PowerShell Data Upload Script (20 min)
**Skill:** PowerShell scripting, SQL, loop logic

**Bug Location:** `DataUpload/Enrollment2024/DataUpload.ps1` line 38  
**Bug:** Variable `$value` is overwritten each loop iteration instead of accumulated  
**Impact:** Only last student from CSV is inserted

**Solution:**
```powershell
# Initialize before loop:
$values = ""

# Inside loop, change from:
$value = "(...)"

# To:
$values += "(...)"  # Use += and $values (plural)

# After loop, use $values instead of $value
```

**Verification:** All students from CSV are inserted into database

---

## Quick Start for Interviewers

1. **Verify bugs exist:**
   ```powershell
   # Bug 1 - Database name typo
   cat Api/appsettings.json | Select-String "DatabaseName"
   # Should show: "sqldb-tfls-d4a635oijzpb" (missing 'c')

   # Bug 2 - Assignment instead of accumulation
   cat Models/Models/Student.cs | Select-String "totalCredits ="
   # Should show: totalCredits = (int)...

   # Bug 3 - Overwriting instead of accumulating
   cat DataUpload/Enrollment2024/DataUpload.ps1 | Select-String '$value ='
   # Should show: $value = "..."
   ```

2. **Ensure database has sample data:**
   - Student "Carson Alexander" with 3 enrollments totaling 9 credits

3. **Share repository with candidate**

4. **Start 60-minute timer**

---

## Assessment Objectives

### What This Tests
✅ Ability to read and understand error messages  
✅ Using logs and debugging tools (Application Insights, console output)  
✅ Code comprehension (reading unfamiliar codebase)  
✅ Debugging logic errors  
✅ Testing and verification  
✅ Time management  
✅ C# fundamentals (loops, null-safety)  
✅ PowerShell scripting (loops, string manipulation)  
✅ SQL awareness (injection prevention)  

### What This Doesn't Test
❌ Advanced algorithm design  
❌ System architecture  
❌ Deep Azure knowledge  
❌ Writing code from scratch  

---

## Scoring Quick Reference

### Excellent Candidate (3/3 questions complete)
- Uses diagnostic tools effectively
- Minimal, targeted fixes
- Tests all changes
- Considers edge cases (nulls, SQL injection)
- Completes in < 60 minutes

### Good Candidate (2-3 questions complete)
- Finds and fixes bugs
- Tests solutions
- May miss some edge cases
- Completes most questions in time

### Needs Improvement (< 2 questions complete)
- Guesses at solutions without diagnosing
- Doesn't test changes
- Makes excessive changes
- Poor time management

---

## Time Benchmarks

- **0-20 min:** Working on Question 1, should have it diagnosed
- **20-40 min:** Working on Question 2, Q1 complete
- **40-60 min:** Working on Question 3, Q2 complete
- **60 min:** All questions complete (ideal)

---

## Common Issues

### "Database connection fails even after fix"
- Check they're running in Development mode: `dotnet run --environment Development`
- Verify database credentials are correct
- Confirm database exists and has sample data

### "Student total still shows wrong value"
- Did they rebuild? (`dotnet build`)
- Did they restart the API and portal?
- Did they fix both the loop AND add null safety?

### "PowerShell script fails with SQL error"
- Did they provide valid connection details?
- Did they escape single quotes in names?
- Did they fix the accumulation AND the trailing comma?

---

## Files Structure

```
TFL-DevOps-Test/
├── README.md                         # Candidate-facing assessment
├── AssessorGuide/                    # ⚠️ DELETE BEFORE SHARING
│   ├── README.md                     # Removal instructions
│   ├── SOLUTIONS.md                  # Complete solutions
│   ├── INTERVIEWER_SETUP.md          # Setup guide
│   └── ASSESSMENT_SUMMARY.md         # This file
├── Api/
│   ├── Program.cs                   # Q1 related
│   ├── appsettings.json             # Q1: typo here
│   └── appsettings.Development.json
├── Models/Models/
│   └── Student.cs                   # Q2: line 19
└── DataUpload/Enrollment2024/
    └── DataUpload.ps1               # Q3: line 38
```

---

## Next Steps

1. Review `INTERVIEWER_SETUP.md` for detailed setup
2. Review `SOLUTIONS.md` for scoring rubric
3. Test all three bugs work in your environment
4. Prepare database with sample data
5. Schedule your interview!

---

## Contact

For questions about this assessment, contact [your team/email].

**Version:** 1.0  
**Last Updated:** November 2025
