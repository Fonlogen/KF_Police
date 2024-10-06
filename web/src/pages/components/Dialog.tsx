import React, { useState, useEffect } from 'react'

interface DialogProps {
  title?: string;
  body?: string;
  show?: boolean;
  background?: any;
  options?: any;
  onClose?: () => void;
  className?: any;
  style?: any;
}

/**
 * Dialog component
 * @param props
 * @returns Callback function if onClose is defined
 * @param title [optional] Title text
 * @param body [optional] Body text
 * @param show [optional] Show dialog
 * @param options [optional] Options
 * @param background [optional] Background image
 * @param onClose [optional] Callback function
 * @param className [optional] Override default className (Additional classes)
 * @param style [optional] Override default style
 */
function Dialog( props: DialogProps ) {

  const [show, setShow] = useState(props?.show);

  const handleClose = () => {
    if (props?.onClose) {
      props?.onClose();
    }

    setShow(false);
  }

  return (
    <>
    { show && props?.background &&
      <div className={`modal-background ${props?.className?.background}`} style={props?.style?.background}></div>
    }
    { show && 
      <div className={`modal-dialog ${props?.className?.dialog}`} style={props?.style?.dialog}>
        <div className={`modal-content ${props?.className?.content}`} style={props?.style?.content}>
          <div className={`modal-header ${props?.className?.header}`} style={props?.style?.header}>
            <h5 className='modal-title'>{props?.title}</h5>
            <button type='button' className='btn-close' data-bs-dismiss='modal' aria-label='Close'></button>
          </div>
          <div className={`modal-body ${props?.className?.body}`} style={props?.style?.body}>
            <p>{props?.body}</p>
          </div>
          <div className={`modal-footer ${props?.className?.footer}`} style={props?.style?.footer}>
            { props?.options && props?.options.map((option: any, index: number) => (
              <button key={index} type='button' className={`btn ${option?.style}`} onClick={option?.onClick}>{option?.label}</button>
            ))}
            { !props?.options && <button type='button' className='btn btn-secondary' data-bs-dismiss='modal' onClick={handleClose}>Close</button>}
          </div>
        </div>
      </div>
    }
    </>
  )
}

interface InputDialogProps {
  title?: string;
  body?: string;
  show?: boolean;
  background?: any;
  options?: any; // Options can be buttons, inputs of any kind or other components ecc
  onClose?: () => void;
  className?: any;
  style?: any;
}

/**
 * InputDialog component
 * @param props
 * @returns Callback function if onClose is defined
 * @param title [optional] Title text
 * @param body [optional] Body text
 * @param show [optional] Show dialog
 * @param background [optional] Background image
 * @param onClose [optional] Callback function
 * @param className [optional] Override default className (Additional classes)
 * @param style [optional] Override default style
 * @param options [optional] Options can be buttons, inputs of any kind or other components ecc
 * @param options.type [optional] Type of option (button, input, select, custom)
 * @param options.label [optional] Label for button
 * @param options.className [optional] Override default className (Additional classes)
 * @param options.style [optional] Override default style
 * @param options.onClick [optional] Callback function
 * @param options.inputType [optional] Input type
 * @param options.placeholder [optional] Input placeholder
 * @param options.value [optional] Input value
 * @param options.onChange [optional] Input onChange function
 * @param options.options [optional] Select options
*/
function InputDialog( props: InputDialogProps ) {
  const [show, setShow] = useState(props?.show);

  const handleClose = () => {
    if (props?.onClose) {
      props?.onClose();
    }

    setShow(false);
  } 

  return (
    <>
    { show && props?.background &&
      <div className={`modal-background ${props?.className?.background}`} style={props?.style?.background}></div>
    }
    { show && 
      <div className={`modal-dialog ${props?.className?.dialog}`} style={props?.style?.dialog}>
        <div className={`modal-content ${props?.className?.content}`} style={props?.style?.content}>
          <div className={`modal-header ${props?.className?.header}`} style={props?.style?.header}>
            <h5 className='modal-title'>{props?.title}</h5>
            <button type='button' className='btn-close' data-bs-dismiss='modal' aria-label='Close'></button>
          </div>
          <div className={`modal-body ${props?.className?.body}`} style={props?.style?.body}>
            <p>{props?.body}</p>
          </div>
          <div className={`modal-footer ${props?.className?.footer}`} style={props?.style?.footer}>
            { props?.options && props?.options.map((option: any, index: number) => {
              if (option?.type === 'button') {
                return <button key={index} type='button' className={`btn ${option?.className}`} onClick={option?.onClick}>{option?.label}</button>;
              } else if (option?.type === 'input') {
                return <input key={index} type={option?.inputType} className={`form-control ${option?.className}`} placeholder={option?.placeholder} value={option?.value} onChange={option?.onChange} />;
              } else if (option?.type === 'select') {
                return <select key={index} className={`form-select ${option?.className}`} value={option?.value} onChange={option?.onChange}>{option?.options.map((opt: any, idx: number) => (<option key={idx} value={opt?.value}>{opt?.label}</option>))}</select>;
              } else if (option?.type === 'custom') {
                return option?.component;
              } else {
                return null;
              }
            })}
            { !props?.options && <button type='button' className='btn btn-secondary' data-bs-dismiss='modal' onClick={handleClose}>Close</button>}
          </div>
        </div>
      </div>
    }
    </>
  )
}

export { Dialog, InputDialog }