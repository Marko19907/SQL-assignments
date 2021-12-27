/*
    Core task set
 */


-- 1. Find the titles of all movies directed by Steven Spielberg.

SELECT title
FROM Movie
WHERE director = 'Steven Spielberg';


-- 2. Find all years that have a movie that received a rating of 4 or 5, and sort them in increasing order.

SELECT year
FROM Rating, Movie
WHERE Rating.mID = Movie.mID
  AND (Rating.stars = 4 OR Rating.stars = 5)
GROUP BY year
ORDER BY year ASC;


-- 3. Find the titles of all movies that have no ratings.

SELECT Movie.title
FROM Movie
    LEFT JOIN Rating
        ON Movie.mID = Rating.mID
WHERE Rating.rID IS NULL;


-- 4. Some reviewers didn't provide a date with their rating. Find the names of all reviewers who have ratings with a NULL value for the date.

SELECT Reviewer.name
FROM Reviewer, Rating
WHERE Reviewer.rID = Rating.rID
  AND Rating.ratingDate IS NULL;


-- 5. Write a query to return the ratings data in a more readable format: reviewer name, movie title, stars, and ratingDate. Also, sort the data, first by reviewer name, then by movie title, and lastly by number of stars.

SELECT Reviewer.name as reviewerName, Movie.title, Rating.stars, Rating.ratingDate
FROM Reviewer, Movie, Rating
WHERE Movie.mID = Rating.mID
  AND Rating.rID = Reviewer.rID
ORDER BY name, title, stars ASC;


-- 6. For all cases where the same reviewer rated the same movie twice and gave it a higher rating the second time, return the reviewer's name and the title of the movie.

WITH
    RatingCopy1 AS (
        SELECT *
        FROM Rating
    ),
    RatingCopy2 AS (
        SELECT *
        FROM Rating
    )

SELECT Reviewer.name, Movie.title
FROM Reviewer, Movie, RatingCopy1, RatingCopy2
WHERE Movie.mID = RatingCopy1.mID
  AND Movie.mID = RatingCopy2.mID
  AND Reviewer.rID = RatingCopy1.rID
  AND Reviewer.rID = RatingCopy2.rID
  AND RatingCopy1.stars < RatingCopy2.stars
  AND RatingCopy1.ratingDate < RatingCopy2.ratingDate;


-- 7. For each movie that has at least one rating, find the highest number of stars that movie received. Return the movie title and number of stars. Sort by movie title.

SELECT Movie.title, Rating.stars
FROM Movie, Rating
WHERE Movie.mID = Rating.mID
GROUP BY title
HAVING max(stars)
ORDER BY title ASC;


-- 8. For each movie, return the title and the 'rating spread', that is, the difference between highest and lowest ratings given to that movie. Sort by rating spread from highest to lowest, then by movie title.

SELECT Movie.title, max(Rating.stars) - min(Rating.stars) as delta
FROM Movie, Rating
WHERE Movie.mID = Rating.mID
GROUP BY title
ORDER BY delta DESC, title ASC;


-- 9. Find the difference between the average rating of movies released before 1980 and the average rating of movies released after 1980. (Make sure to calculate the average rating for each movie, then the average of those averages for movies before 1980 and movies after. Don't just calculate the overall average rating before and after 1980.)

WITH before1980 AS (
    SELECT Movie.mID, AVG(Rating.stars) AS avgStars
    FROM Movie, Rating
    WHERE Movie.mID = Rating.mID
      AND Movie.year < 1980
    GROUP BY Movie.mID
),
     after1980 AS (
         SELECT Movie.mID, AVG(Rating.stars) AS avgStars
         FROM Movie, Rating
         WHERE Movie.mID = Rating.mID
           AND Movie.year > 1980
         GROUP BY Movie.mID
     )

SELECT AVG(before1980.avgStars) - AVG(after1980.avgStars) AS delta
FROM after1980, before1980;


/*
    Extras
 */


-- 1. Find the names of all reviewers who rated Gone with the Wind.

WITH
    movieID AS(
        SELECT Movie.mID
        FROM Movie
        WHERE Movie.title = 'Gone with the Wind'
    ),
    reviewers AS(
        SELECT DISTINCT(Rating.rID) AS rID
        FROM Rating, movieID
        WHERE Rating.mID = movieID.mID
    )

SELECT DISTINCT(Reviewer.name)
FROM Reviewer, Movie, reviewers
WHERE Reviewer.rID IN (reviewers.rID);


-- 2. For any rating where the reviewer is the same as the director of the movie, return the reviewer name, movie title, and number of stars.

SELECT Reviewer.name, Movie.title, Rating.stars
FROM Movie, Reviewer, Rating
WHERE Movie.director = Reviewer.name
  AND Reviewer.rID = Rating.rID
  AND Rating.mID = Movie.mID;


-- 3. Return all reviewer names and movie names together in a single list, alphabetized. (Sorting by the first name of the reviewer and first word in the title is fine; no need for special processing on last names or removing "The".)

SELECT Reviewer.name
FROM Reviewer
UNION
SELECT Movie.title
FROM Movie
ORDER BY name, title;


-- 4. Find the titles of all movies not reviewed by Chris Jackson.

SELECT DISTINCT Movie.title
FROM Movie
WHERE Movie.mID NOT IN (
    SELECT Movie.mID
    FROM Movie, Rating
    WHERE Movie.mID = Rating.mID
      AND Rating.rID IN (
        SELECT Reviewer.rID
        FROM Reviewer
        WHERE Reviewer.name = 'Chris Jackson'
    )
)
ORDER BY title;


-- 5. For all pairs of reviewers such that both reviewers gave a rating to the same movie, return the names of both reviewers. Eliminate duplicates, don't pair reviewers with themselves, and include each pair only once. For each pair, return the names in the pair in alphabetical order.

WITH
    RatingCopy1 AS (
        SELECT *
        FROM Rating
    ),
    RatingCopy2 AS (
        SELECT *
        FROM Rating
    ),
    ReviewerCopy1 AS (
        SELECT *
        FROM Reviewer
    ),
    ReviewerCopy2 AS (
        SELECT *
        FROM Reviewer
    )

SELECT DISTINCT ReviewerCopy1.name AS name1, ReviewerCopy2.name AS name2
FROM ReviewerCopy1, ReviewerCopy2, RatingCopy1, RatingCopy2
WHERE RatingCopy1.mID = RatingCopy2.mID
  AND ReviewerCopy1.rID != ReviewerCopy2.rID
  AND ReviewerCopy1.rID = RatingCopy1.rID
  AND ReviewerCopy2.rID = RatingCopy2.rID

  -- Removes duplicates
  AND ReviewerCopy1.name < ReviewerCopy2.name
ORDER BY name1, name2;


-- 6. For each rating that is the lowest (fewest stars) currently in the database, return the reviewer name, movie title, and number of stars.

WITH
    lowestStars AS (
        SELECT MIN(Rating.stars)
        FROM Rating
    )

SELECT Reviewer.name, Movie.title, Rating.stars
FROM Reviewer, Movie, Rating
WHERE Movie.mID = Rating.mID
  AND Rating.rID = Reviewer.rID
  AND Rating.stars IN lowestStars;


-- 7. List movie titles and average ratings, from highest-rated to lowest-rated. If two or more movies have the same average rating, list them in alphabetical order.

WITH
    avgRating AS (
        SELECT Rating.mID, AVG(Rating.stars) AS avgStars
        FROM Rating
        GROUP BY Rating.mID
    )

SELECT Movie.title, avgRating.avgStars
FROM Movie, avgRating
WHERE Movie.mID = avgRating.mID
ORDER BY avgStars DESC, title;


-- 8. Find the names of all reviewers who have contributed three or more ratings. (As an extra challenge, try writing the query without HAVING or without COUNT.)

WITH reviewerMap AS (
    SELECT Rating.rID, COUNT(Rating.rID) AS counter
    FROM Rating
    GROUP BY Rating.rID
)

SELECT Reviewer.name
FROM reviewerMap
         JOIN Reviewer ON Reviewer.rID = reviewerMap.rID
WHERE ReviewerMap.counter >= 3;


-- 9. Some directors directed more than one movie. For all such directors, return the titles of all movies directed by them, along with the director name. Sort by director name, then movie title. (As an extra challenge, try writing the query without HAVING or without COUNT.)

WITH directorMap AS (
    SELECT Movie.mID, Movie.director, COUNT(Movie.director) AS counter
    FROM Movie
    WHERE Movie.director IS NOT NULL
    GROUP BY Movie.director
)

SELECT Movie.title, Movie.director
FROM Movie
WHERE Movie.director IN (
    SELECT directorMap.director
    FROM directorMap
    WHERE counter >= 2
)
ORDER BY director, title;


-- 10. Find the movie(s) with the highest average rating. Return the movie title(s) and average rating. (Hint: This query is more difficult to write in SQLite than other systems; you might think of it as finding the highest average rating and then choosing the movie(s) with that average rating.)

WITH
    avgRating AS (
        SELECT Rating.mID, AVG(Rating.stars) AS avgStars
        FROM Rating
        GROUP BY Rating.mID
    )

SELECT Movie.title, avgRating.avgStars AS highestRating
FROM Movie, avgRating
WHERE Movie.mID = avgRating.mID
  AND avgRating.avgStars = (
    SELECT MAX(avgRating.avgStars)
    FROM avgRating
)
;


-- 11. Find the movie(s) with the lowest average rating. Return the movie title(s) and average rating. (Hint: This query may be more difficult to write in SQLite than other systems; you might think of it as finding the lowest average rating and then choosing the movie(s) with that average rating.)

WITH
    avgRating AS (
        SELECT Rating.mID, AVG(Rating.stars) AS avgStars
        FROM Rating
        GROUP BY Rating.mID
    )

SELECT Movie.title, avgRating.avgStars AS lowestRating
FROM Movie, avgRating
WHERE Movie.mID = avgRating.mID
  AND avgRating.avgStars = (
    SELECT MIN(avgRating.avgStars)
    FROM avgRating
)
;


-- 12. For each director, return the director's name together with the title(s) of the movie(s) they directed that received the highest rating among all of their movies, and the value of that rating. Ignore movies whose director is NULL.

WITH
    highestRating AS (
        SELECT Rating.mID, MAX(Rating.stars) AS maxStars
        FROM Rating
        GROUP BY Rating.mID
    )

SELECT Movie.director, Movie.title, MAX(highestRating.maxStars) AS stars
FROM Movie, highestRating
WHERE Movie.mID = highestRating.mID
  AND Movie.director IS NOT NULL
GROUP BY director;


/*
    Modification
 */


-- 1. Add the reviewer Roger Ebert to your database, with an rID of 209.

INSERT
INTO Reviewer(rID, name)
VALUES(209, 'Roger Ebert');


-- 2. Insert 5-star ratings by James Cameron for all movies in the database. Leave the review date as NULL.

WITH
    cameronID AS (
        SELECT Reviewer.rID AS rID
        FROM Reviewer
        WHERE Reviewer.name = 'James Cameron'
        GROUP BY Reviewer.rID
    )

INSERT
INTO Rating(rID, mID, stars, ratingDate)
SELECT cameronID.rID, Movie.mID, 5, NULL
FROM Movie, cameronID;


-- 3. For all movies that have an average rating of 4 stars or higher, add 25 to the release year. (Update the existing tuples; don't insert new tuples.)

WITH
    avgRatingMap AS (
        SELECT Movie.mID, AVG(Rating.stars) AS avg
        FROM Movie, Rating
        WHERE Movie.mID = Rating.mID
        GROUP BY Movie.mID
    )

UPDATE Movie
SET year = year + 25
WHERE Movie.mID IN (
    SELECT Movie.mID
    FROM Movie, avgRatingMap
    WHERE Movie.mID = avgRatingMap.mID
      AND avgRatingMap.avg >= 4
);


-- 4. Remove all ratings where the movie's year is before 1970 or after 2000, and the rating is fewer than 4 stars.

DELETE
FROM Rating
WHERE Rating.mID IN (
    SELECT Movie.mID
    FROM Movie, Rating
    WHERE Movie.mID = Rating.mID
        AND Movie.year < 1970 OR Movie.year > 2000
        AND Rating.stars < 4
);