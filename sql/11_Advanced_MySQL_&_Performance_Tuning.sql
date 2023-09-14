# List all pair of employees who have the same department

select left_table.ssn, right_table.ssn, left_table.dno, right_table.dno
from 
employee left_table
join employee right_table
on left_table.dno = right_table.dno and left_table.ssn < right_table.ssn;

# Print Employee name and manager name

select ssn, super_ssn from employee;

select * from employee;

SELECT 
    CONCAT(left_table.fname, ' ', left_table.lname) AS emp_name,
    CONCAT(right_table.fname,
            ' ',
            right_table.lname) AS manager_name
FROM
    employee left_table
        LEFT JOIN
    employee right_table ON left_table.super_ssn = right_table.ssn;

# Union Operation

select dno, sex, avg(salary)
from employee
where sex = 'M'
group by dno
union
select dno, sex, avg(salary)
from employee
where sex = 'F'
group by dno;

select * from employee
left join department 
on employee.dno = department.dnumber
union
select * from employee
right join department 
on employee.dno = department.dnumber;