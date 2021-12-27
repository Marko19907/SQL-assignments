/*
    Core task set
 */


-- 1. Find the names of all students who are friends with someone named Gabriel.

SELECT Highschooler.name
FROM Highschooler, Friend
WHERE Highschooler.ID = Friend.ID2
  AND Friend.ID1 IN (
    SELECT Highschooler.ID
    FROM Highschooler
    WHERE Highschooler.name = 'Gabriel'
);


-- 2. For every student who likes someone 2 or more grades younger than themselves, return that student's name and grade, and the name and grade of the student they like.

WITH
    gradeIDMap1 AS (SELECT Highschooler.ID AS ID, Highschooler.name AS name, Highschooler.grade AS grade
                    FROM Highschooler, Likes
                    WHERE Highschooler.ID = Likes.ID1),

    gradeIDMap2 AS (SELECT Highschooler.ID AS ID, Highschooler.name AS name, Highschooler.grade AS grade
                    FROM Highschooler, Likes
                    WHERE Highschooler.ID = Likes.ID2)

SELECT gradeIDMap1.name, gradeIDMap1.grade, gradeIDMap2.name, gradeIDMap2.grade
FROM gradeIDMap1, gradeIDMap2, Likes
WHERE gradeIDMap1.ID = Likes.ID1
  AND gradeIDMap2.ID = Likes.ID2
  AND ABS(gradeIDMap2.grade - gradeIDMap1.grade) >= 2;


-- 3. For every pair of students who both like each other, return the name and grade of both students. Include each pair only once, with the two names in alphabetical order.

WITH
    likes1 AS (
        SELECT Highschooler.ID AS ID, Highschooler.name AS name, Highschooler.grade AS grade, Likes.ID2 AS likes1
        FROM Highschooler, Likes
        WHERE Highschooler.ID = Likes.ID1
    ),
    likes2 AS (
        SELECT Highschooler.ID AS ID, Highschooler.name AS name, Highschooler.grade AS grade, Likes.ID1 AS likes1
        FROM Highschooler, Likes
        WHERE Highschooler.ID = Likes.ID2
    )

SELECT likes1.name, likes1.grade, likes2.name AS name1, likes2.grade AS grade1
FROM likes1, likes2, Likes
WHERE likes1.ID = Likes.ID2
  AND likes2.ID = Likes.ID1
  AND likes1.name < likes2.name
GROUP BY likes1.name, name1
ORDER BY likes1.name, likes2.name;


-- 4. Find all students who do not appear in the Likes table (as a student who likes or is liked) and return their names and grades. Sort by grade, then by name within each grade.

SELECT Highschooler.name, Highschooler.grade
FROM Highschooler, Likes
WHERE Highschooler.ID NOT IN (
    SELECT Highschooler.ID
    FROM Highschooler, Likes
    WHERE Highschooler.ID = Likes.ID1
       OR Highschooler.ID = Likes.ID2
)
GROUP BY name, grade
ORDER BY grade, name;


-- 5. For every situation where student A likes student B, but we have no information about whom B likes (that is, B does not appear as an ID1 in the Likes table), return A and B's names and grades.

WITH
    studentA AS (
        SELECT Likes.ID1 AS ID, Highschooler.name AS name, Highschooler.grade AS grade
        FROM Likes, Highschooler
        WHERE Likes.ID1 = Highschooler.ID
    ),
    studentB AS (
        SELECT Likes.ID2 AS ID, Highschooler.name AS name, Highschooler.grade AS grade
        FROM Likes, Highschooler
        WHERE Likes.ID2 = Highschooler.ID
          AND Likes.ID2 NOT IN (
            SELECT Likes.ID1
            FROM Likes
        )
    )

SELECT studentA.name, studentA.grade, studentB.name AS name1, studentB.grade AS grade1
FROM studentA, studentB, Likes
WHERE studentB.ID = Likes.ID2
  AND studentA.ID = Likes.ID1
GROUP BY studentA.name, studentA.grade, studentB.name, studentB.grade;


-- 6. Find names and grades of students who only have friends in the same grade. Return the result sorted by grade, then by name within each grade.

SELECT Highschooler1.name, Highschooler1.grade
FROM Highschooler AS Highschooler1
WHERE Highschooler1.ID NOT IN (
    -- Find all the friends in a different grade
    SELECT Friend.ID1
    FROM Highschooler AS Highschooler2, Friend
    WHERE Friend.ID1 = Highschooler1.ID
      AND Friend.ID2 = Highschooler2.ID
      AND Highschooler1.grade != Highschooler2.grade
)
GROUP BY grade, name
ORDER BY grade, name;


-- 7. For each student A who likes a student B where the two are not friends, find if they have a friend C in common (who can introduce them!). For all such trios, return the name and grade of A, B, and C.

WITH
    HighschoolerCopy1 AS (
        SELECT *
        FROM Highschooler
    ),
    HighschoolerCopy2 AS (
        SELECT *
        FROM Highschooler
    ),
    HighschoolerCopy3 AS (
        SELECT *
        FROM Highschooler
    ),
    FriendCopy1 AS (
        SELECT *
        FROM Friend
    ),
    FriendCopy2 AS (
        SELECT *
        FROM Friend
    )

SELECT DISTINCT HighschoolerCopy1.name, HighschoolerCopy1.grade,
                HighschoolerCopy2.name AS name1, HighschoolerCopy2.grade AS grade1,
                HighschoolerCopy3.name AS name2, HighschoolerCopy3.grade AS grade2
FROM HighschoolerCopy1, HighschoolerCopy2, HighschoolerCopy3,
     Likes, FriendCopy1, FriendCopy2
WHERE HighschoolerCopy2.ID NOT IN (
    SELECT Friend.ID2
    FROM Friend
    WHERE Friend.ID1 = HighschoolerCopy1.ID
)
  AND (HighschoolerCopy1.ID = Likes.ID1 AND HighschoolerCopy2.ID = Likes.ID2)
  AND (HighschoolerCopy1.ID = FriendCopy1.ID1 AND HighschoolerCopy3.ID = FriendCopy1.ID2)
  AND (HighschoolerCopy2.ID = FriendCopy2.ID1 AND HighschoolerCopy3.ID = FriendCopy2.ID2);


-- 8. Find the difference between the number of students in the school and the number of different first names.

SELECT COUNT(Highschooler.ID) - COUNT(DISTINCT(Highschooler.name))
FROM Highschooler;


-- 9. Find the name and grade of all students who are liked by more than one other student.

SELECT Highschooler.name, Highschooler.grade
FROM Highschooler
WHERE Highschooler.ID IN (
    SELECT Likes.ID2
    FROM Likes
    GROUP BY Likes.ID2
    HAVING count() >= 2
);


/*
    Extras
 */


-- 1. For every situation where student A likes student B, but student B likes a different student C, return the names and grades of A, B, and C.

WITH
    LikesCopy1 AS (
        SELECT *
        FROM Likes
    ),
    LikesCopy2 AS (
        SELECT *
        FROM Likes
    ),
    HighschoolerCopy1 AS (
        SELECT *
        FROM Highschooler
    ),
    HighschoolerCopy2 AS (
        SELECT *
        FROM Highschooler
    ),
    HighschoolerCopy3 AS (
        SELECT *
        FROM Highschooler
    )

SELECT HighschoolerCopy1.name, HighschoolerCopy1.grade,
       HighschoolerCopy2.name, HighschoolerCopy2. grade,
       HighschoolerCopy3.name, HighschoolerCopy3.grade
FROM HighschoolerCopy1, HighschoolerCopy2, HighschoolerCopy3, LikesCopy1, LikesCopy2
WHERE HighschoolerCopy1.ID = LikesCopy1.ID1
  AND HighschoolerCopy2.ID = LikesCopy1.ID2
  AND HighschoolerCopy3.ID = LikesCopy2.ID2

  AND HighschoolerCopy2.ID = LikesCopy2.ID1
  AND HighschoolerCopy1.ID != HighschoolerCopy3.ID;


-- 2. Find those students for whom all of their friends are in different grades from themselves. Return the students' names and grades.

SELECT Highschooler1.name, Highschooler1.grade
FROM Highschooler AS Highschooler1
WHERE Highschooler1.ID NOT IN (
    SELECT Friend.ID1
    FROM Highschooler AS Highschooler2, Friend
    WHERE Friend.ID1 = Highschooler1.ID
      AND Friend.ID2 = Highschooler2.ID
      AND Highschooler1.grade = Highschooler2.grade
);


-- 3. What is the average number of friends per student? (Your result should be just one number.)

WITH friendMap AS (
    SELECT Friend.ID1, count() AS count
    FROM Friend
    GROUP BY Friend.ID1
)

SELECT AVG(friendMap.count)
FROM friendMap;


-- 4. Find the number of students who are either friends with Cassandra or are friends of friends of Cassandra. Do not count Cassandra, even though technically she is a friend of a friend.

WITH cassandraFriends AS (
    SELECT Friend.ID2 AS ID
    FROM Friend, Highschooler
    WHERE Friend.ID1 = Highschooler.ID
      AND Highschooler.name = 'Cassandra'
)

SELECT count(*)
FROM Friend, cassandraFriends
WHERE Friend.ID1 IN (cassandraFriends.ID);


-- 5. Find the name and grade of the student(s) with the greatest number of friends.

WITH friendMap AS (
    SELECT Friend.ID1, count() AS count
    FROM Friend
    GROUP BY Friend.ID1
)

SELECT Highschooler.name, Highschooler.grade
FROM friendMap, Highschooler
WHERE friendMap.ID1 = Highschooler.ID
  AND friendMap.count = (
    SELECT MAX(friendMap.count)
    FROM friendMap
);


/*
    Modification
 */


-- 1. It's time for the seniors to graduate. Remove all 12th graders from Highschooler.

DELETE
FROM Highschooler
WHERE Highschooler.grade = 12;


-- 2. If two students A and B are friends, and A likes B but not vice-versa, remove the Likes tuple.

DELETE
FROM Likes
WHERE (Likes.ID1, Likes.ID2) IN (
    SELECT Likes.ID1, Likes.ID2
    FROM Likes
)
  AND (Likes.ID2, Likes.ID1) NOT IN (
    SELECT Likes.ID1, Likes.ID2
    FROM Likes
)
  AND (Likes.ID1, Likes.ID2) IN (
    SELECT Friend.ID1, Friend.ID2
    FROM Friend
);


-- 3. For all cases where A is friends with B, and B is friends with C, add a new friendship for the pair A and C. Do not add duplicate friendships, friendships that already exist, or friendships with oneself. (This one is a bit challenging; congratulations if you get it right.)

WITH
    FriendCopy1 AS (
        SELECT *
        FROM Friend
    ),
    FriendCopy2 AS (
        SELECT *
        FROM Friend
    ),
    FriendCopy3 AS (
        SELECT *
        FROM Friend
    )

INSERT
INTO Friend(ID1, ID2)
SELECT DISTINCT FriendCopy1.ID1, FriendCopy2.ID2
FROM FriendCopy1, FriendCopy2
WHERE FriendCopy1.ID2 = FriendCopy2.ID1
  AND FriendCopy1.ID1 != FriendCopy2.ID2
  AND (FriendCopy1.ID1, FriendCopy2.ID2) NOT IN FriendCopy3;