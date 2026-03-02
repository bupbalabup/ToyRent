import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import {
  getProvinces,
  getDistrictsByProvince,
  getWardsByDistrict
} from '../services/location.service.js';
import AppError from '../utils/appError.js';

export const listProvinces = asyncHandler(async (req, res) => {
  const provinces = await getProvinces();
  return sendResponse(res, 200, 'Provinces fetched', { provinces });
});

export const listDistricts = asyncHandler(async (req, res) => {
  const { provinceCode } = req.params;

  if (!provinceCode) {
    throw new AppError('provinceCode is required', 400);
  }

  const districts = await getDistrictsByProvince(provinceCode);
  return sendResponse(res, 200, 'Districts fetched', { districts });
});

export const listWards = asyncHandler(async (req, res) => {
  const { districtCode } = req.params;

  if (!districtCode) {
    throw new AppError('districtCode is required', 400);
  }

  const wards = await getWardsByDistrict(districtCode);
  return sendResponse(res, 200, 'Wards fetched', { wards });
});
