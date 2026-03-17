const Toy = require('../models/toy.model.js');
const mongoose = require('mongoose');

const isValidUrl = (value) => {
  if (!value) return true;
  try {
    const parsed = new URL(value);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch (_) {
    return false;
  }
};

const normalizeImages = ({ images, imageUrl }) => {
  const fromArray = Array.isArray(images)
    ? images
        .map((item) => (typeof item === 'string' ? item.trim() : ''))
        .filter((item) => item.length > 0)
    : [];

  if (fromArray.length > 0) {
    return fromArray;
  }

  if (typeof imageUrl === 'string' && imageUrl.trim().length > 0) {
    return [imageUrl.trim()];
  }

  return [];
};

const isNonNegativeNumber = (value) => Number.isFinite(Number(value)) && Number(value) >= 0;
const isPositiveInteger = (value) => Number.isInteger(Number(value)) && Number(value) > 0;
const isNonNegativeInteger = (value) => Number.isInteger(Number(value)) && Number(value) >= 0;

const createToy = async (req, res, next) => {
  try {
    const { name, rentalPrice, depositAmount, maxRentalDuration, stock, imageUrl, images, categoryId } = req.body;

    if (
      !name ||
      rentalPrice === undefined ||
      depositAmount === undefined ||
      stock === undefined
    ) {
      return res.status(400).json({
        success: false,
        message: 'name, rentalPrice, depositAmount and stock are required',
        data: {}
      });
    }

    if (!isNonNegativeNumber(rentalPrice) || !isNonNegativeNumber(depositAmount) || !isNonNegativeInteger(stock)) {
      return res.status(400).json({
        success: false,
        message: 'rentalPrice, depositAmount must be >= 0 and stock must be a non-negative integer',
        data: {}
      });
    }

    if (maxRentalDuration !== undefined && !isPositiveInteger(maxRentalDuration)) {
      return res.status(400).json({
        success: false,
        message: 'maxRentalDuration must be a positive integer',
        data: {}
      });
    }

    if (categoryId !== undefined && categoryId !== null && String(categoryId).trim().length > 0 && !mongoose.Types.ObjectId.isValid(categoryId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid categoryId',
        data: {}
      });
    }

    const normalizedImages = normalizeImages({ images, imageUrl });

    if (normalizedImages.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'images is required and must contain at least one valid http/https URL',
        data: {}
      });
    }

    if (!normalizedImages.every(isValidUrl)) {
      return res.status(400).json({
        success: false,
        message: 'All images must be valid http/https URLs',
        data: {}
      });
    }

    const payload = {
      ...req.body,
      imageUrl: normalizedImages[0],
      images: normalizedImages,
      maxRentalDuration: maxRentalDuration ?? 24
    };

    const toy = await Toy.create(payload);
    return res.status(201).json({ success: true, message: 'Toy created', data: { toy } });
  } catch (error) {
    return next(error);
  }
};

const getToys = async (req, res, next) => {
  try {
    const page = Math.max(Number(req.query.page) || 1, 1);
    const limit = Math.min(Math.max(Number(req.query.limit) || 10, 1), 100);
    const skip = (page - 1) * limit;

    const query = {};

    if (req.query.categoryId) {
      query.categoryId = req.query.categoryId;
    }

    if (req.query.isActive !== undefined) {
      query.isActive = req.query.isActive === 'true';
    }

    if (req.query.q) {
      const searchRegex = new RegExp(req.query.q, 'i');
      query.$or = [
        { name: searchRegex },
        { description: searchRegex }
      ];
    }

    const [toys, total] = await Promise.all([
      Toy.find(query)
        .populate('categoryId')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Toy.countDocuments(query)
    ]);

    return res.status(200).json({
      success: true,
      message: 'Toys fetched',
      data: {
        items: toys,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    return next(error);
  }
};

const getToyById = async (req, res, next) => {
  try {
    const toy = await Toy.findById(req.params.id).populate('categoryId');

    if (!toy) {
      return res.status(404).json({ success: false, message: 'Toy not found', data: {} });
    }

    return res.status(200).json({ success: true, message: 'Toy fetched', data: { toy } });
  } catch (error) {
    return next(error);
  }
};

const updateToy = async (req, res, next) => {
  try {
    const { imageUrl, images, rentalPrice, depositAmount, stock, maxRentalDuration, categoryId } = req.body;

    if (images !== undefined && !Array.isArray(images)) {
      return res.status(400).json({
        success: false,
        message: 'images must be an array of URLs',
        data: {}
      });
    }

    if (imageUrl !== undefined && (typeof imageUrl !== 'string' || !isValidUrl(imageUrl))) {
      return res.status(400).json({
        success: false,
        message: 'imageUrl must be a valid http/https URL',
        data: {}
      });
    }

    if (rentalPrice !== undefined && !isNonNegativeNumber(rentalPrice)) {
      return res.status(400).json({ success: false, message: 'rentalPrice must be >= 0', data: {} });
    }

    if (depositAmount !== undefined && !isNonNegativeNumber(depositAmount)) {
      return res.status(400).json({ success: false, message: 'depositAmount must be >= 0', data: {} });
    }

    if (stock !== undefined && !isNonNegativeInteger(stock)) {
      return res.status(400).json({ success: false, message: 'stock must be a non-negative integer', data: {} });
    }

    if (maxRentalDuration !== undefined && !isPositiveInteger(maxRentalDuration)) {
      return res.status(400).json({ success: false, message: 'maxRentalDuration must be a positive integer', data: {} });
    }

    if (categoryId !== undefined && categoryId !== null && String(categoryId).trim().length > 0 && !mongoose.Types.ObjectId.isValid(categoryId)) {
      return res.status(400).json({ success: false, message: 'Invalid categoryId', data: {} });
    }

    let normalizedImages;
    if (images !== undefined || imageUrl !== undefined) {
      normalizedImages = normalizeImages({ images, imageUrl });

      if (normalizedImages.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'images must contain at least one valid http/https URL',
          data: {}
        });
      }

      if (!normalizedImages.every(isValidUrl)) {
        return res.status(400).json({
          success: false,
          message: 'All images must be valid http/https URLs',
          data: {}
        });
      }
    }

    const payload = {
      ...req.body
    };

    if (normalizedImages) {
      payload.images = normalizedImages;
      payload.imageUrl = normalizedImages[0];
    }

    const toy = await Toy.findByIdAndUpdate(req.params.id, payload, {
      new: true,
      runValidators: true
    });

    if (!toy) {
      return res.status(404).json({ success: false, message: 'Toy not found', data: {} });
    }

    return res.status(200).json({ success: true, message: 'Toy updated', data: { toy } });
  } catch (error) {
    return next(error);
  }
};

const deleteToy = async (req, res, next) => {
  try {
    const toy = await Toy.findByIdAndDelete(req.params.id);

    if (!toy) {
      return res.status(404).json({ success: false, message: 'Toy not found', data: {} });
    }

    return res.status(200).json({ success: true, message: 'Toy deleted', data: { toyId: toy._id } });
  } catch (error) {
    return next(error);
  }
};

module.exports = { createToy, getToys, getToyById, updateToy, deleteToy };
