const Toy = require('../models/toy.model.js');

const createToy = async (req, res, next) => {
  try {
    const { name, rentalPrice, depositAmount, maxRentalDuration, stock } = req.body;

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

    const payload = {
      ...req.body,
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
    const payload = {
      ...req.body
    };

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
