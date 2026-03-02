# Maintenance Management System
## Sumitomo Wiring Systems - Application

A comprehensive web-based maintenance management system built with Flask, designed to manage:
- **Stock Management** - Inventory tracking with min/max alerts
- **Preventive Maintenance Schedules** - Schedule and track maintenance tasks
- **Spare Parts Demand Workflow** - Multi-step approval process
- **Dashboard** - Real-time KPIs and monitoring

---

## Features

### 1. Stock Management
- Material inventory tracking
- Min/Max stock level alerts
- Email notifications for critical stock levels
- Stock movement history
- Material categorization
- Supplier management

### 2. Preventive Maintenance Schedules
- Machine maintenance scheduling
- Supervisor assignment
- Technician work reports
- Maintenance history tracking
- Issue documentation

### 3. Spare Parts Demand Workflow
- Technician/Supervisor request creation
- Supervisor approval step
- Stock agent allocation step
- Email notifications at each stage
- Demand status tracking
- Material availability checking

### 4. Dashboard
- Real-time statistics
- Maintenance countdown
- Pending approvals
- Stock alerts
- Recent activities
- Role-based access control

---

## System Requirements

- Python 3.8+
- MySQL 5.7+
- Pip (Python package manager)

---

## Installation

### Step 1: Set Up Database

Open MySQL and execute the provided SQL script:

```bash
mysql -u root -p < database.sql
```

Or:

```sql
source /path/to/database.sql;
```

### Step 2: Install Python Dependencies

```bash
pip install -r requirements.txt
```

### Step 3: Configure Environment Variables

Edit the `.env` file with your database credentials:

```env
MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASSWORD=your_password
MYSQL_DB=maintenance_system
```

### Step 4: Initialize the Application

```bash
python main.py
```

The application will:
1. Connect to MySQL database
2. Create necessary tables (if not already present)
3. Start the Flask development server at `http://localhost:5000`

---

## Default Credentials

| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | Admin |
| supervisor | sup123 | Supervisor |
| technician | tech123 | Technician |
| stock_agent | stock123 | Stock Agent |

---

## User Roles & Permissions

### Admin
- Full system access
- User management
- System configuration
- View all data

### Supervisor
- Create & assign maintenance schedules
- Approve spare parts demands
- View maintenance reports
- Monitor technician activities

### Technician
- View assigned maintenance schedules
- Create maintenance reports
- Submit spare parts demands
- View stock levels

### Stock Agent
- Manage inventory
- Add/edit materials
- Approve spare parts allocations
- Track stock movements
- Send stock alerts

---

## Project Structure

```
App stage 2026/
├── app/
│   ├── __init__.py              # App factory and initialization
│   ├── models/
│   │   └── __init__.py          # SQLAlchemy models
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── auth.py              # Authentication routes
│   │   ├── main.py              # Dashboard and stock management
│   │   ├── maintenance.py       # Maintenance routes
│   │   └── demands.py           # Spare parts demand routes
│   ├── templates/               # Jinja2 HTML templates
│   │   ├── base.html            # Base template
│   │   ├── auth/                # Auth templates
│   │   ├── main/                # Dashboard templates
│   │   ├── stock/               # Stock management templates
│   │   ├── maintenance/         # Maintenance templates
│   │   └── demands/             # Demands templates
│   └── static/
│       ├── css/
│       │   └── style.css        # Custom CSS
│       ├── js/
│       │   └── main.js          # Custom JavaScript
│       └── images/              # Images and logos
├── config.py                    # Configuration settings
├── main.py                      # Application entry point
├── database.sql                 # Database schema
├── requirements.txt             # Python dependencies
├── .env                         # Environment variables
└── README.md                    # This file
```

---

## Running the Application

### Development Mode
```bash
python main.py
```

Or with Flask CLI:
```bash
flask run
```

### Production Mode

Edit `.env`:
```env
FLASK_ENV=production
DEBUG=False
```

Then use a production server like Gunicorn:
```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 main:app
```

---

## Database Management

### Initialize Database
```bash
python main.py
# or using Flask CLI
flask init-db
```

### Seed Sample Data
```bash
flask seed-db
```

---

## API Endpoints Summary

### Authentication
- `GET/POST /auth/login` - User login
- `GET /auth/logout` - User logout
- `GET/POST /auth/register` - User registration (admin only)
- `GET/POST /auth/profile` - View/edit user profile

### Dashboard
- `GET /` - Main dashboard
- `GET /dashboard` - Dashboard view

### Stock Management
- `GET /stock/` - Material inventory list
- `GET/POST /stock/add` - Add new material
- `GET/POST /stock/edit/<id>` - Edit material
- `GET /stock/detail/<id>` - Material detail view
- `GET /stock/alerts` - Stock alerts

### Maintenance
- `GET /maintenance/` - Schedules list
- `GET/POST /maintenance/create` - Create schedule
- `GET /maintenance/<id>` - Schedule detail
- `GET/POST /maintenance/<id>/report` - Create maintenance report
- `GET /maintenance/report/<id>` - Report detail

### Demands
- `GET /demands/` - Demands list
- `GET/POST /demands/create` - Create demand
- `GET /demands/<id>` - Demand detail
- `POST /demands/<id>/supervisor-approve` - Supervisor approval
- `POST /demands/<id>/stock-approve` - Stock agent approval

---

## Features in Development

- [ ] PowerBI dashboard integration
- [ ] Advanced reporting and analytics
- [ ] Mobile app (React Native)
- [ ] Real-time notifications (WebSocket)
- [ ] Automated email scheduling
- [ ] Barcode scanning for materials
- [ ] Equipment monitoring integration

---

## Troubleshooting

### Database Connection Error
```
Error: Can't connect to MySQL server
```
**Solution:** 
1. Ensure MySQL is running
2. Check credentials in `.env`
3. Verify database `maintenance_system` exists

### Module Import Error
```
ModuleNotFoundError: No module named 'flask'
```
**Solution:**
```bash
pip install -r requirements.txt
```

### Port Already in Use
```
Address already in use
```
**Solution:**
```bash
# Change port in main.py
app.run(port=5001)
```

---

## Configuration Options

Edit `config.py` to customize:

- Database URL
- Session timeout
- MAIL settings
- Items per page
- File upload limits

---

## Security Considerations

1. **Change default credentials** immediately
2. **Set strong SECRET_KEY** for production
3. **Use HTTPS** in production
4. **Enable SESSION_COOKIE_SECURE** for HTTPS
5. **Regular database backups**
6. **Keep dependencies updated**

```bash
pip install --upgrade -r requirements.txt
```

---

## Support & Contact

For issues or questions:
- Check the troubleshooting section
- Review application logs
- Contact IT Support at Sumitomo Wiring Systems

---

## License

This application is proprietary software of Sumitomo Wiring Systems.

---

## Changelog

### Version 1.0 (Initial Release)
- Stock management module
- Maintenance scheduling
- Spare parts demand workflow
- User authentication and roles
- Dashboard with KPIs
- Email notifications

---

**Last Updated:** February 2026
**Version:** 1.0.0
