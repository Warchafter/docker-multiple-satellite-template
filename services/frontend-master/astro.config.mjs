// @ts-check
import { defineConfig } from 'astro/config';
import react from '@astrojs/react';
import node from '@astrojs/node';

// https://astro.build/config
export default defineConfig({
    output: 'server',
    adapter: node({mode: 'standalone'}),
    server: { host: true, port: 4321 },
    integrations: [
        react(),
        // Tailwind CSS v4 is automatically integrated with Astro
    ],
});