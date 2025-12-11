# Technical Assessment Solutions Guide

**For Interviewers Only** - Do not share with candidates

---

## Question 1: API Configuration Issue

### The Bug
The API fails to start or connect to the database due to a configuration mismatch.

**Root Cause:**
- `Api/appsettings.json` contains `DatabaseConnection:DatabaseName` = `sqldb-tfls-d4a635oijzpb` (typo, missing 'c')
- `Api/Program.cs` builds the connection string using this incorrect database name
- The correct database name is `sqldb-tfls-d4a635oijzpbc`
- Meanwhile, `appsettings.Development.json` has a correct connection string under `ConnectionStrings:TflSchoolApiContext`, but it's not being used

### Solution 1 (Best Practice)
Modify `Api/Program.cs` to prefer `ConnectionStrings` configuration:

```csharp
// Replace the connection string building code with:
var connection = builder.Configuration.GetConnectionString("TflSchoolApiContext");

if (string.IsNullOrEmpty(connection))
{
    var dbName = builder.Configuration["DatabaseConnection:DatabaseName"];
    var userName = builder.Configuration["DatabaseConnection:UserName"];
    var password = builder.Configuration["DatabaseConnection:Password"];
    
    connection = $"Server=tcp:sql-tfls-d4a635oijzpbc.database.windows.net,1433;Initial Catalog={dbName};Persist Security Info=False;User ID={userName};Password={password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
}

builder.Services.AddDbContext<TflDbContext>(opt =>
    opt.UseSqlServer(connection, sqlOptions => sqlOptions.EnableRetryOnFailure())
);
```

### Solution 2 (Quick Fix)
Fix the typo in `Api/appsettings.json`:

```json
"DatabaseConnection": {
  "DatabaseName": "sqldb-tfls-d4a635oijzpbc",  // Added 'c' at the end
  "UserName": "appUser",
  "Password": ""
}
```

### Verification
```powershell
cd Api
dotnet run --environment Development
# Should start without errors

# In another terminal:
curl http://localhost:5000/api/Students
# Should return JSON array (may be empty, but HTTP 200)
```

### Scoring Criteria
- **Excellent:** Uses logging/console output to diagnose, implements Solution 1 (proper fallback)
- **Good:** Identifies the typo, fixes it, tests successfully
- **Needs Improvement:** Guesses at the solution without using diagnostic tools

---

## Question 2: C# Logic Error

### The Bug
The `Student.TotalCredits` property returns only the last enrollment's credits instead of the sum.

**Root Cause:**  
In `Models/Models/Student.cs`, line 17:
```csharp
totalCredits = (int)enrollment.Course.Credits;  // Assignment, not accumulation!
```

This **assigns** the value on each iteration instead of **adding** to it.

### Solution
Change line 17 from assignment to addition:

```csharp
public int TotalCredits
{
    get
    {
        var totalCredits = 0;
        
        if (Enrollments != null)
        {
            foreach(var enrollment in Enrollments)
            {
                totalCredits += enrollment?.Course?.Credits ?? 0;  // Use += and null-safe
            }
        }
        
        return totalCredits;
    }
}
```

### Key Changes
1. `=` changed to `+=` (accumulation)
2. Added null check for `Enrollments` collection
3. Added null-safe navigation with `??` operator

### Verification
```powershell
# Terminal 1
cd Api
dotnet run

# Terminal 2
cd StudentPortal
dotnet run

# Browser: Search for "Carson Alexander"
# Before fix: Total Credits = 3
# After fix: Total Credits = 9
```

### Scoring Criteria
- **Excellent:** Fixes accumulation bug AND adds null safety
- **Good:** Fixes the `=` to `+=` bug, tests successfully
- **Needs Improvement:** Fixes bug but doesn't test or consider edge cases

---

## Question 3: PowerShell Loop Bug

### The Bug
The script only inserts the last student from the CSV file because `$value` is overwritten in each loop iteration.

**Root Cause:**  
In `DataUpload/Enrollment2024/DataUpload.ps1`, lines 33-36:

```powershell
$students | ForEach-Object {
    $value = "('$($_.FirstMidName)','$($_.LastName)','$($_.EnrollmentDate)'),"
}
$insertStudentsQuery = $insertStudentsQuery + $value  # Only has last value!
```

The variable `$value` is reassigned (not appended) on each iteration.

### Solution
Initialize an accumulator before the loop and append inside:

```powershell
# Before the loop (around line 33):
$values = ""

$students | ForEach-Object {
    # Escape single quotes to prevent SQL injection
    $firstName = $_.FirstMidName -replace "'", "''"
    $lastName = $_.LastName -replace "'", "''"
    
    $values += "('$firstName','$lastName','$($_.EnrollmentDate)'),"
}

# After the loop:
$insertStudentsQuery = $insertStudentsQuery + $values
$insertStudentsQuery = $insertStudentsQuery.Substring(0, $insertStudentsQuery.LastIndexOf(","))
```

### Key Changes
1. Created `$values` accumulator (plural)
2. Used `+=` inside the loop to append
3. Added SQL injection protection by escaping single quotes
4. After the loop, trimmed the trailing comma as before

### Verification
```powershell
cd DataUpload\Enrollment2024

# Check how many students in CSV
(Import-Csv .\Students.csv).Count  # Should show 4

# Run the script (adjust connection details)
.\DataUpload.ps1 -InstanceName "server.database.windows.net" `
                 -DatabaseName "dbname" `
                 -SqlAdminUser "user" `
                 -SqlAdminPassword "pass"

# Should see "INSERT STUDENTS FINISHED" without rollback
```

### Scoring Criteria
- **Excellent:** Fixes accumulation bug AND adds SQL injection protection (quote escaping)
- **Good:** Fixes the accumulation bug, verifies correct row count
- **Needs Improvement:** Fixes bug but doesn't test or consider SQL injection

---

## Overall Assessment Rubric

### Time Management
- Completes all 3 questions in ~60 minutes
- Prioritizes getting working solutions over perfect solutions

### Diagnostic Approach
- Uses logs and error messages effectively
- Reads code to understand context before making changes
- Tests fixes to verify they work

### Code Quality
- Makes minimal, targeted changes
- Considers edge cases (nulls, empty collections, special characters)
- Follows existing code style

### Communication
- Can explain what was wrong
- Can explain how the fix works
- Asks clarifying questions if needed

### Red Flags
- Makes random changes without understanding the problem
- Doesn't test their fixes
- Over-engineers solutions
- Gives up without trying diagnostic tools

---

## Setup Notes for Interviewers

### Prerequisites
1. Ensure the database has sample data (students "Carson Alexander" with 3 enrollments)
2. Application Insights connection string can be empty for local testing
3. SQL Server instance accessible for Question 3 (or provide connection details)

### Timing Suggestions
- Start timer when candidate begins reading
- 20-minute checkpoint: Should be working on Question 2
- 40-minute checkpoint: Should be working on Question 3
- 10 minutes remaining: Suggest prioritizing working solutions

### Observation Points
- Do they read error messages carefully?
- Do they use debugging/logging tools?
- Do they test incrementally or make multiple changes at once?
- How do they handle uncertainty?

---

## Common Mistakes to Watch For

### Question 1
- Changing the wrong configuration file
- Not restarting the API after config changes
- Ignoring console error messages

### Question 2
- Fixing the accumulation but breaking null safety
- Not rebuilding after code changes
- Testing with the wrong student

### Question 3
- Not understanding PowerShell variable scope
- Forgetting to escape special characters
- Not verifying the actual insert count

---

Good luck with your interviews!
