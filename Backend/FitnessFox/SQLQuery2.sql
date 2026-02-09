-- 1. On met la date d'activité à HIER (Simulation du passé)
UPDATE Users 
SET LastActivityDate = DATEADD(day, -1, GETDATE()) 
WHERE Pseudo = 'FoxWarrior';

-- 2. On coche manuellement toutes les missions (Simulation du travail fait)
UPDATE Missions 
SET IsCompleted = 1;