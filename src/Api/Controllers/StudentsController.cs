using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using TFL.DevOps.Api.Data;
using TFL.DevOps.Models;

namespace TFL.DevOps.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class StudentsController : ControllerBase
    {
        private readonly TflDbContext _context;
        private readonly ILogger<StudentsController> _logger;

        public StudentsController(TflDbContext context, ILogger<StudentsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        // GET: api/Students
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Student>>> GetStudents()
        {
            try
            {
                return await _context.Students
                    .Include(s => s.Enrollments)
                    .ThenInclude(e => e.Course)
                    .AsNoTracking()
                    .ToListAsync();
            }
            catch(Exception ex)
            {
                _logger.LogError(ex,"GetStudents has failed");
                return StatusCode(500);
            }
        }

        // GET: api/Students/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Student>> GetStudent(int id)
        {
            try
            {
                var student = await _context.Students
                                .Include(s => s.Enrollments)
                                .ThenInclude(e => e.Course)
                                .FirstAsync(s => s.Id == id);

                if (student == null)
                {
                    return NotFound();
                }
                
                return student;
            }
            catch(Exception ex)
            {
                _logger.LogError(ex,"GetStudent has failed");
                return StatusCode(500);
            }
        }

        // PUT: api/Students/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public async Task<IActionResult> PutStudent(int id, Student student)
        {
            if (id != student.Id)
            {
                return BadRequest();
            }

            _context.Entry(student).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!StudentExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // POST: api/Students
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost]
        public async Task<ActionResult<Student>> PostStudent(Student student)
        {
            _context.Students.Add(student);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetStudent", new { id = student.Id }, student);
        }

        // DELETE: api/Students/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteStudent(int id)
        {
            var student = await _context.Students.FindAsync(id);
            if (student == null)
            {
                return NotFound();
            }

            _context.Students.Remove(student);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool StudentExists(int id)
        {
            return _context.Students.Any(e => e.Id == id);
        }
    }
}
