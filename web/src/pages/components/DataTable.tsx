import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import React from 'react';
import { Tooltip } from 'react-tooltip';
import { StringContainsAny } from '../../utils/utils';

const ImageFormats = ['.jpg', '.png', '.svg'];

interface DataTableProps {
  header?: string;
  emptyMessage?: string;
  rows: any;
  columns: any;
  style?: any;
  size?: { [key: string]: string }; // Add size prop
}

function DataTable({ header, emptyMessage, rows, columns, style, size }: DataTableProps) {
  return (
    <>
      <h2 className='text-2xl w-full text-left font-bold'>{header}</h2>
      <div className={`flex-table ${style?.table || null}`}>
        <div className={`flex-table-header ${style?.header}`}>
          {Object.keys(columns).map((column: string, index: number) => (
            <div
              key={index}
              className={`flex-table-cell ${style?.cell || null}`}
              style={{ width: size?.[column] || 'auto' }} // Apply size if specified
            >
              {columns[column]}
            </div>
          ))}
        </div>
        <div className={`flex-table-body ${style?.body}`}>
          {rows &&
            rows.map((row: any, index: number) => (
              <div key={index} className={`flex-table-row ${style?.row || null}`}>
                {Object.keys(columns).map((column: string, colIndex: number) => (
                  <div
                    key={colIndex}
                    className={`flex-table-cell ${style?.cell || null}`}
                    style={{ width: size?.[column] || 'auto' }} // Apply size if specified
                  >
                    {typeof row[column] !== 'object' && (
                      <>
                        {StringContainsAny(row[column], ImageFormats) ? (
                          <img src={row[column]} />
                        ) : (
                          typeof row[column] === 'string' && row[column].startsWith('http') ? '' : row[column]
                        )}
                      </>
                    )}

                    {!Array.isArray(row[column]) && row[column] && row[column]?.type === 'button' && (
                      row[column].tooltip !== null ? (
                        <>
                          <Tooltip
                            id={`ttp-${index}-${colIndex}`}
                            place={row[column].tooltip?.place || 'bottom'}
                            variant={row[column].tooltip?.variant || null}
                            content={row[column].tooltip?.text}
                            style={{ backgroundColor: "#121212" }}
                          />
                          <button
                            key={column}
                            data-tooltip-id={`ttp-${index}-${colIndex}`}
                            className={`datatable-action-btn ${row[column].style || 'bg-blue-500'}`}
                            onClick={row[column].function || row[column].onClick || row[column].action || null}
                          >
                            {StringContainsAny(row[column], ImageFormats) ? <img src={row[column]} /> : null}
                            {row[column]?.icon && <FontAwesomeIcon icon={row[column].icon} />}
                            {row[column].label}
                          </button>
                        </>
                      ) : (
                        <button
                          key={column}
                          className={`datatable-action-btn ${row[column].style || 'bg-red-500'}`}
                          onClick={row[column].function || row[column].onClick || row[column].action || null}
                        >
                          {StringContainsAny(row[column], ImageFormats) ? <img src={row[column]} /> : null}
                          {row[column]?.icon && <FontAwesomeIcon icon={row[column].icon} />}
                          {row[column]?.label}
                        </button>
                      )
                    )}
                    {Array.isArray(row[column]) && row[column].map((btn: any, btnIndex: number) => (
                      <React.Fragment key={btnIndex}>
                        {btn.tooltip !== null ? (
                          <>
                            <Tooltip
                              id={`ttp-${index}-${colIndex}-${btnIndex}`}
                              place={btn.tooltip?.place || 'bottom'}
                              variant={btn.tooltip?.variant || null}
                              content={btn.tooltip?.text}
                              style={{ backgroundColor: "#121212" }}
                            />
                            <button
                              data-tooltip-id={`ttp-${index}-${colIndex}-${btnIndex}`}
                              className={`datatable-action-btn ${btn.style || 'bg-blue-500'}`}
                              onClick={btn.function || btn.onClick || btn.action || null}
                            >
                              {StringContainsAny(row[column], ImageFormats) ? <img src={row[column]} /> : null}
                              {btn?.icon && <FontAwesomeIcon icon={btn.icon} />}
                              {btn?.label}
                            </button>
                          </>
                        ) : (
                          <button
                            className={`datatable-action-btn ${btn.style || 'bg-red-500'}`}
                            onClick={btn.function || btn.onClick || btn.action || null}
                          >
                            {StringContainsAny(row[column], ImageFormats) ? <img src={row[column]} /> : null}
                            {btn?.icon && <FontAwesomeIcon icon={btn.icon} />}
                            {btn.label}
                          </button>
                        )}
                      </React.Fragment>
                    ))}
                  </div>
                ))}
              </div>
            ))}
          {(!rows || rows.length <= 0) && (
            <div className={`flex-table-row ${style?.row || null}`}>
              {Object.keys(columns).map((column: string, colIndex: number) => (
                <div key={colIndex} className={`flex-table-cell ${style?.cell || null}`} style={{ width: size?.[column] || 'auto' }}>
                  {colIndex === 0 ? (emptyMessage || 'Nessun dato') : ''}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </>
  );
}

export default DataTable;