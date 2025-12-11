[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $InstanceName,

    [Parameter()]
    [string]
    $DatabaseName,

    [Parameter()]
    [string]
    $SqlAdminUser,

    [Parameter()]
    [string]
    $SqlAdminPassword
)

# Install Module
Write-Host "Getting latest module versions"
Install-Module SqlServer -Force -AllowClobber

# Create Database connection string
Write-Host "Building connection string"
$connectionString = "Server=tcp:$($InstanceName),1433;Initial Catalog=$($DatabaseName);Persist Security Info=False;User ID=$($SqlAdminUser);Password=$($SqlAdminPassword);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

### SECTION - UPLOAD STUDENT RECORDS ###
# Read students CSV
Write-Host "*** INSERT STUDENTS ***"
Write-Host "Reading data from Students.csv"
$students = Import-Csv -Path $PSScriptRoot\Students.csv

# Build student insert query
Write-Host "Building Query for student insert"
$insertStudentsQuery = "DECLARE @expected_inserts int; DECLARE @actual_inserts int; SET XACT_ABORT ON; SET @expected_inserts = $($students.Count); BEGIN TRANSACTION; INSERT INTO [dbo].[Students] (FirstMidName,LastName,EnrollmentDate) VALUES "
$students | ForEach-Object {
    $value = "('$($_.FirstMidName)','$($_.LastName)','$($_.EnrollmentDate)'),"
}
$insertStudentsQuery = $insertStudentsQuery + $value 
$insertStudentsQuery = $insertStudentsQuery.Substring(0, $insertStudentsQuery.LastIndexOf(","))
$insertStudentsQuery = $insertStudentsQuery + "; SET @actual_inserts = @@ROWCOUNT; IF @actual_inserts = @expected_inserts COMMIT TRANSACTION; ELSE ROLLBACK TRANSACTION;"

# Invoke student insert
Write-Host "Invoking Student insert query"
Invoke-Sqlcmd -ConnectionString $connectionString -Query $insertStudentsQuery -Verbose
Write-Host "*** INSERT STUDENTS FINISHED ***"
### END SECTION ###

### SECTION - UPLOAD NEW STUDENT ENROLLMENTS ###
Write-Host "*** UPLOAD STUDENT ENROLLMENT ***"
# Read Enrollment CSV
Write-Host "Reading data from Enrollments.csv"
$enrollments = Import-Csv -Path $PSScriptRoot\Enrollments.csv

# Iterate each enrollment
$enrollments | ForEach-Object {
    # Build query to get student 
    $studentFirstName = $_.FirstMidName
    $studentLastName = $_.LastName
    $courseId = $_.CourseId
    Write-Host "Building query to get Id of student $($studentFirstName) $($studentLastName)"
    $getStudentIdQuery = "SELECT Id FROM [dbo].[Students] WHERE FirstMidName = '$($studentFirstName)' AND LastName = '$($studentLastName)'"

    # Invoke query to get student ID
    Write-Host "Invoke query to get Student Id"
    $result = (Invoke-Sqlcmd -ConnectionString $connectionString -Query $getStudentIdQuery)
    
    if($result) {
        $studentId = $result["Id"]
        # Creating query to insert enrollment
        Write-Host "Building query to insert Enrollment data"
        $insertEnrollmentQuery = "SET XACT_ABORT ON; BEGIN TRANSACTION; INSERT INTO [dbo].[Enrollments] (CourseId,StudentId) VALUES ((SELECT CourseID FROM [dbo].[Courses] WHERE CourseId = $($courseId)),(SELECT Id FROM [dbo].[Students] Where Id = $($studentId))); COMMIT TRANSACTION;" 
        
        # Invoke enrollment insert
        Write-Host "Invoking query to upload Enrollment for student $($studentFirstName) $($studentLastName) to course Id $($courseId)"
        Invoke-Sqlcmd -ConnectionString $connectionString -Query $insertEnrollmentQuery -Verbose
    }
    else {
        Write-Warning "Unable to find Id of student $($studentFirstName) $($studentLastName). Please check student record has been created."
    }
}
Write-Host "*** UPLOAD STUDENT ENROLLMENT FINISHED ***"
### END SECTION ###

Write-Host "Data upload script has finished."