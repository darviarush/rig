<?php declare(strict_types=1);

namespace Restoclub\Migrations;

use Doctrine\DBAL\Migrations\AbstractMigration;
use Doctrine\DBAL\Schema\Schema;

/**
 * Auto-generated Migration: Please modify to your needs!
 * make sf-up-migration env=dev n={{timestamp}}
 */
final class Version{{timestamp}} extends AbstractMigration
{
    private function checkDBPlatform(): void
    {
        if ($this->connection->getDatabasePlatform()->getName() !== 'postgresql') {
            $this->abortIf(true, "Migration can only be executed safely on 'postgresql'.");
        }
    }

    public function up(Schema $schema) : void
    {
        $this->checkDBPlatform();
        $this->addSql("ALTER TABLE public.ex ADD COLUMN active BOOLEAN NOT NULL;");
    }

    public function down(Schema $schema) : void
    {
        $this->checkDBPlatform();
        $this->addSql("ALTER TABLE public.ex DROP active;");
    }
}
