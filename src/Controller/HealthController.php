<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Annotation\Route;

class HealthController extends AbstractController
{
    #[Route('/ping', name: 'app_health')]
    public function index(): JsonResponse
    {
        return $this->json([
            'pong'
        ]);
    }
}
