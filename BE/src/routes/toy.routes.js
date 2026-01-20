const { Router } = require('express');
const { createToy, getToys, getToyById, updateToy, deleteToy } = require('../controllers/toy.controller.js');
const { protect, allowRoles } = require('../middlewares/auth.middleware.js');

const router = Router();

router.get('/', getToys);
router.get('/:id', getToyById);
router.post('/', protect, allowRoles('admin'), createToy);
router.put('/:id', protect, allowRoles('admin'), updateToy);
router.delete('/:id', protect, allowRoles('admin'), deleteToy);

module.exports = router;
