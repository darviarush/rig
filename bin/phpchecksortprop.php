<?php

declare(strict_types=1);

use PhpParser\Node;
use PhpParser\Node\Attribute;
use PhpParser\Node\Expr\New_;
use PhpParser\NodeTraverser;
use PhpParser\NodeVisitorAbstract;
use PhpParser\ParserFactory;

# composer global require nikic/php-parser


require 'vendor/autoload.php';

class ArgumentOrderValidator extends NodeVisitorAbstract
{
    private array $errors = [];
    private array $use = [];
    private string $filePath;
    
    public function validateFile(string $filePath): void
    {
        $this->filePath = $filePath;
        #$parser = (new ParserFactory())->create(ParserFactory::PREFER_PHP7);
        $parser = (new ParserFactory())->createForHostVersion();
        $ast = $parser->parse(file_get_contents($filePath));
        
        $traverser = new NodeTraverser();
        $traverser->addVisitor($this);
        $traverser->traverse($ast);

        //$this->traverseNodes($ast, $filePath);
        
        if (!empty($this->errors)) {
            echo "Found sorting issues:\n";
            foreach ($this->errors as $error) {
                echo "- $error\n";
            }
            exit(1);
        }
        
        echo "All arguments are properly ordered!\n";
    }
    
    public function enterNode(Node $node) {
        #echo "Visiting node: " . get_class($node) . "\n";

        if ($node instanceof Node\Stmt\Use_) {
            foreach ($node->uses as $use) {
                  // Получаем алиас
                  $alias = $use->getAlias() ? $use->getAlias()->toString() : null;
                  $name = $use->name->toString();
                  #echo "Имя: $name, Алиас: $alias\n"; // Выводим имя и алиас
                  $this->use[$alias] = $name;
            }
        }

        if ($node instanceof New_) {
            $this->checkNew($node);
        }
        
        if ($node instanceof Attribute) {
            $this->checkAttribute($node);
        }
    }
    
    private function checkNew(New_ $node): void
    {
        $className = (string) $node->class;
        $constructorParams = $this->getConstructorParams($className);
        
        $sortedArgs = $this->sortArguments($node->args, $constructorParams);
        if ($this->isOrderIncorrect($node->args, $sortedArgs)) {
            $this->addError($sortedArgs, $node->getLine(), "new {$className}");
        }
    }
    
    private function checkAttribute(Attribute $node): void
    {
        $attributeName = (string) $node->name;
        $constructorParams = $this->getConstructorParams($attributeName);
        
        $sortedArgs = $this->sortArguments($node->args, $constructorParams);
        if ($this->isOrderIncorrect($node->args, $sortedArgs)) {
            $this->addError($sortedArgs, $node->getLine(), "#[{$attributeName}]");
        }
    }
    
    /**
     * @return array<string>
     */
    private function getConstructorParams(string $name): array
    {
        $last = '';
        if (preg_match('/([^\\\\]*)(\\\\.*)/', $name, $matches)) {
            $name = $matches[1];
            $last = $matches[2];
        }

        $className = $this->use[$name] . $last;
        #echo "class $className\n";

        if (!class_exists($className)) {
            return [];
        }

        $reflection = new ReflectionClass($className);
        $constructor = $reflection->getConstructor();
        
        if (!$constructor) {
            return [];
        }
        
        return array_map(
            fn(ReflectionParameter $param) => $param->getName(),
            $constructor->getParameters()
        );
    }
    
    private function sortArguments(array $args, array $constructorParams): array
    {
        $namedArgs = [];
        $unnamedArgs = [];
        
        foreach ($args as $arg) {
            if ($arg->name) {
                $namedArgs[$arg->name->toString()] = $arg;
            } else {
                $unnamedArgs[] = $arg;
            }
        }
        
        $sorted = [];
        foreach ($constructorParams as $paramName) {
            if (isset($namedArgs[$paramName])) {
                $sorted[] = $namedArgs[$paramName];
                unset($namedArgs[$paramName]);
            }
        }
        
        return array_merge($unnamedArgs, $sorted, array_values($namedArgs));
    }
    
    private function isOrderIncorrect(array $original, array $sorted): bool
    {
        return $original !== $sorted;
    }
    
    private function addError(array $sortedArgs, int $line, string $context): void
    {
        $this->errors[] = sprintf(
            "%s:%d %s - %s",
            $this->filePath,
            $line,
            $context,
            implode(", ", array_column($sortedArgs, 'name'))
        );
    }
}

// Использование
if ($argc < 2) {
    echo "Usage: php validate_arguments_order.php <file>\n";
    exit(1);
}

$validator = new ArgumentOrderValidator();
$validator->validateFile($argv[1]);