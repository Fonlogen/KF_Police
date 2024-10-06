export const ConvertToArray = (data: any) => {
  if (typeof data === 'object') {
    return Object.keys(data).map((key: any) => data[key]);
  }
  return data;
}

export const StringContainsAny = (str: string, substrings: string[]) => {
  if (typeof str !== 'string') {
    // console.error('StringContainsAny: str is not a string', typeof str, str);
    return false;
  }
  return substrings.some((substring) => str.includes(substring));
};