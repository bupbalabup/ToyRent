import { Router } from 'express';
import {
  listProvinces,
  listDistricts,
  listWards
} from '../controllers/location.controller.js';

const router = Router();

router.get('/provinces', listProvinces);
router.get('/provinces/:provinceCode/districts', listDistricts);
router.get('/districts/:districtCode/wards', listWards);

export default router;
