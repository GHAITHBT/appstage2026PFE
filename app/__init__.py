from flask import Flask
from config import config
from app.models import db
from flask_session import Session
from flask_mail import Mail
from datetime import timedelta
import os

def create_app(config_name='development'):
    """Application factory"""
    # Get the absolute path to the app directory
    basedir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    app = Flask(__name__,
                template_folder=os.path.join(basedir, 'app', 'templates'),
                static_folder=os.path.join(basedir, 'app', 'static'))
    
    # Load configuration
    app.config.from_object(config[config_name])
    
    # Initialize extensions
    db.init_app(app)
    Session(app)
    
    # Initialize Flask-Mail
    from app.email_service import mail
    mail.init_app(app)
    
    # Register blueprints
    from app.routes.auth import auth_bp
    from app.routes.main import main_bp, stock_bp
    from app.routes.maintenance import maintenance_bp
    from app.routes.demands import demands_bp
    from app.routes.technician import technician_bp
    
    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(main_bp)
    app.register_blueprint(stock_bp)
    app.register_blueprint(maintenance_bp)
    app.register_blueprint(demands_bp)
    app.register_blueprint(technician_bp)
    
    # Context processor to inject user info into templates
    @app.context_processor
    def inject_user_info():
        from flask import session
        user = None
        if 'user_id' in session:
            from app.models import User
            user = User.query.get(session['user_id'])
        return dict(current_user=user)
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return '''
        <html>
            <head>
                <title>Page Not Found</title>
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
            </head>
            <body>
                <div class="d-flex align-items-center justify-content-center min-vh-100">
                    <div class="text-center">
                        <h1 class="display-1">404</h1>
                        <p class="fs-3"><span class="text-danger">Oops!</span> Page not found.</p>
                        <p class="lead">The page you're looking for doesn't exist.</p>
                        <a href="/" class="btn btn-primary">Go Home</a>
                    </div>
                </div>
            </body>
        </html>
        ''', 404
    
    @app.errorhandler(500)
    def server_error(error):
        return '''
        <html>
            <head>
                <title>Server Error</title>
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
            </head>
            <body>
                <div class="d-flex align-items-center justify-content-center min-vh-100">
                    <div class="text-center">
                        <h1 class="display-1">500</h1>
                        <p class="fs-3"><span class="text-danger">Error!</span> Server error.</p>
                        <p class="lead">Something went wrong on the server.</p>
                        <a href="/" class="btn btn-primary">Go Home</a>
                    </div>
                </div>
            </body>
        </html>
        ''', 500
    
    # Shell context for flask shell
    @app.shell_context_processor
    def make_shell_context():
        return {'db': db}
    
    return app
