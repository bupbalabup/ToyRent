const Category = require('../models/category.model.js');

const createCategory = async (req, res, next) => {
  try {
    const { name, icon } = req.body;

    if (!name) {
      return res.status(400).json({ success: false, message: 'name is required', data: {} });
    }

    const category = await Category.create({ name, icon });
    return res.status(201).json({ success: true, message: 'Category created', data: { category } });
  } catch (error) {
    return next(error);
  }
};

const getCategories = async (req, res, next) => {
  try {
    const categories = await Category.find().sort({ createdAt: -1 });
    return res.status(200).json({ success: true, message: 'Categories fetched', data: { categories } });
  } catch (error) {
    return next(error);
  }
};

const getCategoryById = async (req, res, next) => {
  try {
    const category = await Category.findById(req.params.id);

    if (!category) {
      return res.status(404).json({ success: false, message: 'Category not found', data: {} });
    }

    return res.status(200).json({ success: true, message: 'Category fetched', data: { category } });
  } catch (error) {
    return next(error);
  }
};

const updateCategory = async (req, res, next) => {
  try {
    const category = await Category.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });

    if (!category) {
      return res.status(404).json({ success: false, message: 'Category not found', data: {} });
    }

    return res.status(200).json({ success: true, message: 'Category updated', data: { category } });
  } catch (error) {
    return next(error);
  }
};

const deleteCategory = async (req, res, next) => {
  try {
    const category = await Category.findByIdAndDelete(req.params.id);

    if (!category) {
      return res.status(404).json({ success: false, message: 'Category not found', data: {} });
    }

    return res.status(200).json({
      success: true,
      message: 'Category deleted',
      data: { categoryId: category._id }
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = { createCategory, getCategories, getCategoryById, updateCategory, deleteCategory };
