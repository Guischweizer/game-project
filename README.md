# Game Project Setup Guide

This guide will help you set up and run both the server and client components of the game project.

## Prerequisites

- Docker and Docker Compose
- Node.js (v16+)
- yarn

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd game-project
```

### 2. Starting the Backend

The backend uses NestJS with Prisma ORM and PostgreSQL database.

#### Starting the Database

```bash
# From the project root
docker-compose up -d
```

This will start a PostgreSQL database container as defined in your docker-compose file.

#### Running Prisma Migrations

```bash
# Navigate to the server directory
cd server/game-server

# Install dependencies
yarn install

# Run migrations
yarn prisma migrate dev
```

This will apply all pending migrations to your database schema.

#### Starting the Game Server

```bash
# From the server/game-server directory
yarn run start:dev
```

The server will be available at `http://localhost:3000` (or the port specified in your configuration).

### 3. Starting the Frontend

```bash
# Navigate to the client directory
cd client/web-client

# Install dependencies
yarn install

# Start the development server
yarn start
```

The client will be available at `http://localhost:3000` (or automatically on another port if 3000 is in use).

## Development Commands

### Backend Commands

```bash
# Run server in development mode with auto-reload
yarn run start:dev

# Run tests
yarn test

# Run production build
yarn run build
yarn run start:prod

# Generate new Prisma migrations
yarn prisma migrate dev --name migration_name

# Apply new Prisma migrations
yarn prisma migrate deploy
```

### Frontend Commands

```bash
# Start development server
yarn start

# Build for production
yarn run build

# Run tests
yarn test
```

## Environment Variables

Make sure to set up the appropriate environment variables for both the server and client:

### Server (.env file in server/game-server)
```
DATABASE_URL="postgresql://postgres:password@localhost:5432/gamedb?schema=public"
JWT_SECRET=your_jwt_secret
```

### Client (.env file in client/web-client)
```
REACT_APP_API_URL=http://localhost:3000
```

## Troubleshooting

- If you encounter database connection issues, ensure Docker is running and the PostgreSQL container is up.
- For Prisma errors, try running `yarn prisma generate` to update the Prisma client.
- If the client can't connect to the server, check for CORS settings in the NestJS configuration.

## Stripe Integration

### Setting Up Stripe

1. Create a Stripe account at [stripe.com](https://stripe.com) if you don't have one

2. Get your API keys from the Stripe Dashboard:
   - Go to Developers > API keys
   - Copy both the publishable key and the secret key

3. Add Stripe environment variables:

   ### Server (.env file in server/game-server)
   ```
   DATABASE_URL="postgresql://postgres:password@localhost:5432/gamedb?schema=public"
   JWT_SECRET=your_jwt_secret
   STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
   STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_key
   ```

   ### Client (.env file in client/web-client)
   ```
   REACT_APP_API_URL=http://localhost:3000
   REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key
   ```

### Setting Up Stripe Webhooks (For Local Development)

1. Install the Stripe CLI from [https://stripe.com/docs/stripe-cli](https://stripe.com/docs/stripe-cli)

2. Login to your Stripe account via CLI:
   ```bash
   stripe login
   ```

3. Start forwarding webhooks to your local server:
   ```bash
   stripe listen --forward-to http://localhost:3000/payments/webhook
   ```

4. The CLI will provide a webhook signing secret. Add this to your server's .env file as STRIPE_WEBHOOK_SECRET.

### Testing Payments

1. Use Stripe's test cards for payment testing:
   - Card number: 4242 4242 4242 4242
   - Expiration: Any future date
   - CVC: Any 3 digits
   - ZIP: Any 5 digits

2. For testing different payment scenarios (like declined payments), refer to [Stripe's test cards documentation](https://stripe.com/docs/testing#cards)
