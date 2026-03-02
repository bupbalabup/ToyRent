import Review from '../models/review.model.js';
import Toy from '../models/toy.model.js';

export const refreshToyRating = async (toyId, session = null) => {
  const aggregateQuery = Review.aggregate([
    { $match: { toyId } },
    {
      $group: {
        _id: '$toyId',
        ratingAverage: { $avg: '$rating' },
        ratingCount: { $sum: 1 }
      }
    }
  ]);

  if (session) {
    aggregateQuery.session(session);
  }

  const stats = await aggregateQuery;

  if (!stats.length) {
    await Toy.findByIdAndUpdate(toyId, { ratingAverage: 0, ratingCount: 0 }, { session });
    return;
  }

  await Toy.findByIdAndUpdate(
    toyId,
    {
      ratingAverage: Number(stats[0].ratingAverage.toFixed(2)),
      ratingCount: stats[0].ratingCount
    },
    { session }
  );
};
