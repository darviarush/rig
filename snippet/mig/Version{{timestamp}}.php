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
        $this->addSql(<<<END
			ALTER TABLE public.ex ADD COLUMN active BOOLEAN NOT NULL;
		END);
        $this->addSql(<<<END
            COMMENT ON COLUMN public.ex.active
                IS '';
        END);
    }

    public function down(Schema $schema) : void
    {
        $this->checkDBPlatform();
        $this->addSql(<<<END
			ALTER TABLE public.ex DROP active;
		END);
    }
}
