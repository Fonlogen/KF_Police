import React from 'react'

/**
 * Props interface for the DepartmentHeader component.
 * 
 * @property {string} deptImage - The URL of the department's image.
 * @property {string} deptText - The text description of the department.
 */
interface Props {
  deptCity: string;
  deptText: string;
  deptImage: string;
  className?: string | undefined;
}

/**
 * 
 * @param {string} deptCity - The city of the department.
 * @param {string} deptText - The text description of the department.
 * @param {string} deptImage - The URL of the department's image.
 * @param {string} className - The class name of the department header that will be added to the existing one.
 * @returns The DepartmentHeader component.
 */
const DepartmentHeader = ({ deptCity, deptText, deptImage, className }: Props) => {
  return (
    <div className="department-header w-[350px] flex flex-row gap-2">
      <img src={deptImage} alt="Department Image" className='h-[100px] w-[100px] object-cover rounded-[50%] ' />
      <div 
        className={`department-header-text flex flex-col justify-center gap-1 text-white text-2xl text-left ${className}`}
      >
        <span className='text-3xl font-bold'>{deptCity}</span>
        <span>{deptText}</span>
      </div>
    </div>
  )
}

export default DepartmentHeader