<?php

declare(strict_types=1);

use PhpParser\Node;
use PhpParser\Node\Attribute;
use PhpParser\Node\Expr\New_;
use PhpParser\ParserFactory;

#require __DIR__ . '/vendor/autoload.php'; // Подключите Composer autoload

class ArgumentOrderValidator
{
    private array $errors = [];
    
    public function validateFile(string $filePath): void
    {
        $parser = (new ParserFactory())->create(ParserFactory::PREFER_PHP7);
        $ast = $parser->parse(file_get_contents($filePath));
        
        $this->traverseNodes($ast, $filePath);
        
        if (!empty($this->errors)) {
            echo "Found sorting issues:\n";
            foreach ($this->errors as $error) {
                echo "- $error\n";
            }
            exit(1);
        }
        
        echo "All arguments are properly ordered!\n";
    }
    
    private function traverseNodes(array $nodes, string $filePath): void
    {
        foreach ($nodes as $node) {
            if ($node instanceof New_) {
                $this->checkNew($node, $filePath);
            }
            
            if ($node instanceof Attribute) {
                $this->checkAttribute($node, $filePath);
            }
            
            if (property_exists($node, 'stmts')) {
                $this->traverseNodes($node->stmts, $filePath);
            }
        }
    }
    
    private function checkNew(New_ $node, string $filePath): void
    {
        try {
            $className = (string) $node->class;
            $constructorParams = $this->getConstructorParams($className);
            
            $sortedArgs = $this->sortArguments($node->args, $constructorParams);
            if ($this->isOrderIncorrect($node->args, $sortedArgs)) {
                $this->addError($filePath, $node->getLine(), "new {$className}");
            }
        } catch (ReflectionException) {
            // Игнорируем классы, которые нельзя отразить
        }
    }
    
    private function checkAttribute(Attribute $node, string $filePath): void
    {
        try {
            $attributeName = (string) $node->name;
            $constructorParams = $this->getConstructorParams($attributeName);
            
            $sortedArgs = $this->sortArguments($node->args, $constructorParams);
            if ($this->isOrderIncorrect($node->args, $sortedArgs)) {
                $this->addError($filePath, $node->getLine(), "#[{$attributeName}]");
            }
        } catch (ReflectionException) {
            // Игнорируем атрибуты без конструктора
        }
    }
    
    /**
     * @return array<string>
     */
    private function getConstructorParams(string $className): array
    {
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
    
    private function addError(string $file, int $line, string $context): void
    {
        $this->errors[] = sprintf(
            "%s:%d - Incorrect argument order in %s",
            basename($file),
            $line,
            $context
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