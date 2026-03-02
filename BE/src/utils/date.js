export const normalizeDateToUTC = (dateInput) => {
  const date = new Date(dateInput);
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
};

export const enumerateDatesUTC = (startDate, endDate) => {
  const dates = [];
  const current = normalizeDateToUTC(startDate);
  const end = normalizeDateToUTC(endDate);

  while (current <= end) {
    dates.push(new Date(current));
    current.setUTCDate(current.getUTCDate() + 1);
  }

  return dates;
};
