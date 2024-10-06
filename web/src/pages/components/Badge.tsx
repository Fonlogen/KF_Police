import React, { useEffect } from 'react'
import { useContext } from 'react'
import { MDTContext } from '../App'

import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

import { 
  faUserShield,
  faUserTie,
  faUserNurse,
  faStar,
  faIdBadge,
  faShield,
  faSkull,
  faSkullCrossbones,
} from '@fortawesome/free-solid-svg-icons'

let jobIcon = {
  'police': faUserShield,
  'ambulance': faUserNurse,
  'mechanic': faUserTie,
  'judge': faStar,
  'lawyer': faIdBadge,
  'news': faShield,
  'wanted': faSkull,
}

let jobColor = {
  'police': 'blue',
  'ambulance': 'green',
  'mechanic': 'yellow',
  'judge': 'purple',
  'lawyer': 'red',
  'news': 'gray',
  'wanted': 'orange',
}

interface BadgeProps {
  job?: any;
  role?: string;
  size?: string;
  text: string;
}

function Badge({ job, role, text, size }: BadgeProps) {
  return (
    <span className={"mx-3 flex flex-row gap-2 bg-" + jobColor[job?.job_name || role] + "-700 text-white px-2 py-1 rounded-lg items-center font-normal text-" + (size || 'lg') + " w-fit"}>
      <FontAwesomeIcon icon={jobIcon[job?.job_name || role]} className='text-white' />
      <span>{text || job?.job_name || role} {job?.job_grade_label && ('• ' + job?.job_grade_label)}</span>
    </span>
  )
}

export default Badge