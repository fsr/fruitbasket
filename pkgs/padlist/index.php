<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);


$host = '/run/postgresql';
$dbname = 'hedgedoc';
$user = 'hedgedoc';

try {
    $dbh = new PDO("pgsql:host=$host;dbname=$dbname", $user);
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
    die();
}

$query = 'SELECT "Notes".title, "Notes"."updatedAt", "Notes"."shortid", "Users".profile  FROM "Notes" JOIN "Users" ON "Notes"."ownerId" = "Users".id WHERE permission = \'freely\' OR permission = \'editable\' OR permission = \'limited\' ORDER BY "Notes"."updatedAt"  DESC';
try {
    $stmt = $dbh->query($query);
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
    die();
}

function formatDateString($stringDate)
{
    $datetime = DateTime::createFromFormat('Y-m-d H:i:s.uP', $stringDate);
    $formattedDate = $datetime->format('d.m.Y H:i');
    return $formattedDate;
}
?>

<!DOCTYPE html>
<html lang="de">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pad lister</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@1/css/pico.min.css">

</head>

<body>
    <div class="container">
        <br><br>
        <table>
            <tr>
                <th>Titel</th>
                <th>Owner</th>
                <th>Last edit</th>
            </tr>

            <?php
            foreach ($rows as $row) {
            ?>
                <tr>
                    <td>
                        <a href="https://pad.ifsr.de/<?= $row['shortid'] ?>"><?= $row['title'] ?></a>
                    </td>
                    <td>
                        <?= json_decode($row['profile'])->username ?>
                    </td>
                    <td>
                        <?= formatDateString($row['updatedAt']) ?>
                    </td>
                </tr>

            <?php
            }
            ?>
        </table>
        <br><br>
    </div>
</body>

</html>