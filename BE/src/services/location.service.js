import env from '../config/env.js';
import AppError from '../utils/appError.js';

const requestJson = async (path) => {
  const response = await fetch(`${env.locationApiBase}${path}`);

  if (!response.ok) {
    throw new AppError('Failed to fetch location data', 502);
  }

  return response.json();
};

export const getProvinces = async () => {
  const provinces = await requestJson('/p/');
  return provinces.map((item) => ({ code: item.code, name: item.name }));
};

export const getDistrictsByProvince = async (provinceCode) => {
  const province = await requestJson(`/p/${provinceCode}?depth=2`);
  return (province.districts || []).map((item) => ({ code: item.code, name: item.name }));
};

export const getWardsByDistrict = async (districtCode) => {
  const district = await requestJson(`/d/${districtCode}?depth=2`);
  return (district.wards || []).map((item) => ({ code: item.code, name: item.name }));
};
